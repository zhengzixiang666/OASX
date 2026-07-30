import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/nav/view_nav.dart';
import 'package:path_provider/path_provider.dart';

import 'package:oasx/utils/check_version.dart';
import 'package:oasx/config/global.dart';
import 'package:oasx/services/device_service.dart';

/// language: String ["en-US", "zh-CN", "zh-TW", "ja-JP"]
/// 关于桌面分辨率的适配： 不知道如何下手
class SettingsController extends GetxController {
  GetStorage storage = GetStorage();
  late String temporaryDirectory;

  // 卡密相关
  final cardKey = ''.obs;
  final cardSaved = false.obs;

  @override
  void onInit() {
    updateTemporaryDirectory();
    getCurrentVersion().then((value) {
      GlobalVar.version = value;
    });
    _loadSavedCardKey();
    super.onInit();
  }

  /// 从 GetStorage 读取已保存的卡密（脱敏显示）
  void _loadSavedCardKey() {
    final saved = storage.read('card_key');
    if (saved != null && saved.toString().isNotEmpty) {
      cardKey.value = saved;
      cardSaved.value = true;
    }
  }

  /// 获取脱敏的卡密显示
  String get maskedCardKey {
    if (cardKey.value.isEmpty) return '';
    if (cardKey.value.length <= 12) return '****';
    return '${cardKey.value.substring(0, 8)}****${cardKey.value.substring(cardKey.value.length - 4)}';
  }

  /// 保存卡密到 card_key.txt
  /// 文件路径：OAS根目录/config/card_key.txt
  /// 内容：JSON { "card_key": "xxx", "device_id": "xxx" }
  Future<bool> saveCardKey(String key) async {
    key = key.trim();
    if (key.isEmpty) {
      Get.snackbar('提示', '卡密不能为空');
      return false;
    }

    try {
      // 获取 OAS 根目录
      final rootPath = storage.read('rootPathServer');
      if (rootPath == null || rootPath.toString().isEmpty) {
        Get.snackbar('错误', '请先在服务器页面设置 OAS 根目录');
        return false;
      }

      // 生成设备ID
      final deviceId = DeviceService.getDeviceId();

      // 写入 card_key.txt
      final cardFile = File('${rootPath}/config/card_key.txt');
      final cardDir = Directory('${rootPath}/config');
      if (!cardDir.existsSync()) {
        cardDir.createSync(recursive: true);
      }

      final data = {
        'card_key': key,
        'device_id': deviceId,
      };
      cardFile.writeAsStringSync(jsonEncode(data));

      // 同时存入 GetStorage（用于界面回显）
      storage.write('card_key', key);
      cardKey.value = key;
      cardSaved.value = true;

      Get.snackbar('成功', '卡密已保存，启动脚本时将自动验证');
      return true;
    } catch (e) {
      Get.snackbar('错误', '保存卡密失败: $e');
      return false;
    }
  }

  /// 清除已保存的卡密
  Future<void> clearCardKey() async {
    try {
      final rootPath = storage.read('rootPathServer');
      if (rootPath != null) {
        final cardFile = File('${rootPath}/config/card_key.txt');
        if (cardFile.existsSync()) {
          cardFile.deleteSync();
        }
      }
      storage.remove('card_key');
      cardKey.value = '';
      cardSaved.value = false;
      Get.snackbar('提示', '卡密已清除');
    } catch (e) {
      Get.snackbar('错误', '清除卡密失败: $e');
    }
  }

  void updateTemporaryDirectory() {
    temporaryDirectory = storage.read('temporaryDirectory') ?? './';
    printInfo(info: 'Old TemporaryDirectory : $temporaryDirectory');
    getTemporaryDirectory().then((value) {
      temporaryDirectory = value.path;
      printInfo(info: 'New TemporaryDirectory : $temporaryDirectory');
      storage.write('temporaryDirectory', temporaryDirectory);
    });
  }

  Future<void> killServer() async {
    final success = await ApiClient().killServer();
    if (success) {
      Get.snackbar(I18n.kill_server_success.tr, '');
      Get.offAllNamed('/login');
      await Future.wait([
        Get.delete<ScriptService>(force: true),
        Get.delete<NavCtrl>(force: true),
      ]);
    } else {
      Get.snackbar(I18n.kill_server_failure.tr, '');
    }
  }
}
