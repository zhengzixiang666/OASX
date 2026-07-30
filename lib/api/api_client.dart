import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter_nb_net/flutter_net.dart';
import 'package:get/get.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:oasx/api/api_interceptor.dart';

import 'package:oasx/component/dio_http_cache/dio_http_cache.dart';
import 'package:oasx/config/translation/i18n.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/settings.dart';
import './update_info_model.dart';

/// common result
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? code;

  bool get isSuccess => data != null;

  ApiResult.success(this.data)
      : error = null,
        code = null;

  ApiResult.failure(this.error, [this.code]) : data = null;
}

class ApiClient {
  // 单例
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    // 防御性获取 temporaryDirectory：SettingsController 可能尚未注册
    // （在 OASXApp.onInit 中才注册，而 LoginController.onInit 可能在之前触发）
    String tempDir = './';
    if (Get.isRegistered<SettingsController>()) {
      tempDir = Get.find<SettingsController>().temporaryDirectory;
    }

    NetOptions.instance
        .setConnectTimeout(const Duration(seconds: 5))
        .setReceiveTimeout(const Duration(seconds: 10))
        .enableLogger(false)
        .addInterceptor(DioCacheInterceptor(
            options: CacheOptions(
          store: FileCacheStore(tempDir),
          policy: CachePolicy.request,
          hitCacheOnErrorExcept: [401, 403],
          maxStale: const Duration(days: 7),
          priority: CachePriority.normal,
          cipher: null,
          keyBuilder: CacheOptions.defaultCacheKeyBuilder,
          allowPostMethod: false,
        )))
        .addInterceptor(ApiInterceptor())
        .setHttpClientAdapter(IOHttpClientAdapter(
          createHttpClient: () {
            // 创建不使用代理的 HttpClient，避免 Clash Verge 等代理拦截本地请求
            final client = HttpClient()
              ..idleTimeout = const Duration(seconds: 3)
              ..findProxy = (uri) => 'DIRECT';
            return client;
          },
        ))
        .create();
  }

  // http://$address 地址的前缀开头
  String address = '127.0.0.1:22288';

  void setAddress(String address) {
    this.address = address;
    NetOptions.instance.dio.options.baseUrl = address;
  }

  /// common request method
  ///
  /// [silent] 为 true 时不弹错误提示（用于页面加载时的自动请求，
  /// 避免 yys.exe 未启动时弹出"网络错误"打扰用户）
  Future<ApiResult<T>> request<T>(Future<Result<T>> Function() apiFn,
      {bool silent = false}) async {
    try {
      final res = await apiFn();
      return res.when(
        success: (data) => ApiResult.success(data),
        failure: (msg, code) {
          printError(info: '${I18n.network_error_code}: $msg | $code'.tr);
          if (!silent) {
            switch (code) {
              case 403:
                break;
              case 404:
                showNetErrCodeSnackBar(I18n.network_not_found.tr, code);
                break;
              default:
                showNetErrCodeSnackBar(msg, code);
                break;
            }
          }
          return ApiResult.failure(msg, code);
        },
      );
    } catch (e) {
      printError(info: '${I18n.network_error.tr}: $e');
      if (!silent) {
        showNetErrSnackBar();
      }
      return ApiResult.failure(e.toString());
    }
  }

// ----------------------------------   服务端地址测试   ----------------------------------
  Future<bool> testAddress() async {
    // 直接用 Dio 发请求，绕过 flutter_nb_net 的 connectivity 检查
    // 因为 OASX 连接的是本地 yys.exe，不需要互联网连接
    try {
      final response = await NetOptions.instance.dio.get('/test');
      return response.data == 'success';
    } catch (e) {
      return false;
    }
  }

  Future<bool> killServer() async {
    final res = await request(() => get('/home/kill_server'));
    return res.isSuccess && res.data == 'success';
  }

// ----------------------------------   杂接口  --------------------------------------------
  Future<bool> notifyTest(String setting, String title, String content) async {
    final res = await request(() => post(
          '/home/notify_test',
          queryParameters: {
            'setting': setting,
            'title': title,
            'content': content
          },
        ));
    if (res.isSuccess && res.data == true) {
      Get.snackbar(I18n.notify_test_success.tr, '');
      return true;
    }
    Get.snackbar(I18n.notify_test_failed.tr, res.data.toString());
    return false;
  }

  Future<UpdateInfoModel> getUpdateInfo() async {
    final res = await request(
      () => get(
        '/home/update_info',
        decodeType: UpdateInfoModel(),
      ),
      silent: true,
    );
    return res.isSuccess ? res.data : UpdateInfoModel();
  }

  Future<String?> getExecuteUpdate() async {
    final res = await request(() => get('/home/execute_update'));
    if (res.isSuccess) {
      showDialog('Update', res.data.toString());
      return res.data;
    }
    return res.data;
  }

  Future<bool> putChineseTranslate() async {
    final res = await request(() => put(
          '/home/chinese_translate',
          data: Messages().all_cn_translate,
        ));
    return res.isSuccess && res.data == true;
  }

  Future<Map<String, Map<String, String>>> getAdditionalTranslate() async {
    final res = await request(() => get('/home/additional_translate'));
    Map<String, Map<String, String>> result = {};
    if (res.isSuccess) {
      result["zh-CN"] = res.data["zh-CN"].cast<String, String>();
      result["en-US"] = res.data["en-US"].cast<String, String>();
    }
    return result;
  }

// ----------------------------------   菜单项管理   ----------------------------------
  Future<Map<String, List<String>>> getScriptMenu() async {
    final res = await request(() => get('/script_menu'));
    return ((res.data ?? {}) as Map).map((k, v) =>
        MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()));
  }

  Future<Map<String, List<String>>> getHomeMenu() async {
    final res = await request(() => get('/home/home_menu'));
    return ((res.data ?? {}) as Map).map((k, v) =>
        MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()));
  }

// ----------------------------------   配置文件管理   ----------------------------------
  Future<List<String>> getConfigList() async {
    final res = await request(() => get('/config_list'));
    return ['Home', ...(res.data?.cast<String>() ?? [])];
  }

  Future<List<String>> getScriptList() async {
    final res = await request(() => get('/config_list'));
    return [...(res.data?.cast<String>() ?? [])];
  }

  Future<String> getNewConfigName() async {
    final res = await request(() => get('/config_new_name'));
    return res.isSuccess ? res.data : '';
  }

  Future<List<String>> configCopy(String newName, String template) async {
    final res = await request(() => post(
          '/config_copy',
          queryParameters: {'file': newName, 'template': template},
        ));
    return ['Home', ...(res.data?.cast<String>() ?? [])];
  }

  Future<List<String>> getConfigAll() async {
    final res = await request(() => get('/config_all'));
    return res.data?.cast<String>() ?? ['template'];
  }

  Future<bool> deleteConfig(String name) async {
    final res = await request(() => delete(
          '/config',
          queryParameters: {'name': name},
        ));
    return res.isSuccess && res.data;
  }

  Future<bool> renameConfig(String oldName, String newName) async {
    final res = await request(() => put(
          '/config',
          queryParameters: {'old_name': oldName, 'new_name': newName},
        ));
    return res.isSuccess && res.data;
  }

// ---------------------------------   脚本实例管理   ----------------------------------

  Future<Map<String, dynamic>> getScriptTask(
      String scriptName, String taskName) async {
    final res = await request(() => get('/$scriptName/$taskName/args'));
    return res.data ?? {};
  }

  Future<bool> putScriptArg(
    String scriptName,
    String taskName,
    String groupName,
    String argumentName,
    String type,
    dynamic value,
  ) async {
    final res = await request(() => put(
          '/$scriptName/$taskName/$groupName/$argumentName/value',
          queryParameters: {'types': type, 'value': value},
        ));
    return res.isSuccess && res.data == true;
  }

// ---------------------------------   任务调度操作   ----------------------------------

  Future<bool> syncNextRun(String scriptName, String task,
      {String? targetDt}) async {
    final res = await request(() => put(
          '/$scriptName/$task/sync_next_run',
          queryParameters: {'target_dt': targetDt ?? ''},
        ));
    return res.isSuccess;
  }

// ---------------------------------   Snackbar --------------------------------
  void showDialog(String title, String content) {
    Get.snackbar(title, content);
  }

  void showNetErrSnackBar() {
    Get.snackbar(I18n.network_error.tr, I18n.network_connect_timeout.tr,
        duration: const Duration(seconds: 2));
  }

  void showNetErrCodeSnackBar(String msg, int code) {
    // 不显示 Dio 的完整英文错误消息，只显示简洁的中文提示
    String hint = '';
    if (code >= 500) {
      hint = 'yys.exe 服务异常，请重启后重试';
    } else if (code == 404) {
      hint = '接口不存在';
    } else if (code == 403) {
      hint = '无权限访问';
    } else {
      hint = '请检查 yys.exe 是否已启动';
    }
    Get.snackbar(I18n.network_error.tr, '${I18n.network_error_code.tr}: $code | $hint',
        duration: const Duration(seconds: 3));
  }
}
