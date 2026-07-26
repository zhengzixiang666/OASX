import 'dart:io';
import 'package:get_storage/get_storage.dart';

/// 设备服务 - 生成和存取设备唯一标识
class DeviceService {
  static const String _deviceKey = 'device_id';

  /// 获取或生成设备唯一标识
  /// 基于主机名 + 用户名 + 硬件信息生成
  static String getDeviceId() {
    final storage = GetStorage();
    String? deviceId = storage.read(_deviceKey);

    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    // 生成新的设备ID
    deviceId = _generateDeviceId();
    storage.write(_deviceKey, deviceId);
    return deviceId;
  }

  /// 生成设备唯一标识
  /// 使用主机名 + 操作系统信息 + 随机数的 MD5
  static String _generateDeviceId() {
    final hostname = Platform.localHostname;
    final os = Platform.operatingSystem;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final raw = '$hostname-$os-$timestamp';

    // 简单哈希（不需要 crypto 包，用内置 hashCode）
    final hash = raw.hashCode.toRadixString(16).padLeft(8, '0');
    final random = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    return '$hash$random'.toUpperCase();
  }
}
