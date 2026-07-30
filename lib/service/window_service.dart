import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:window_manager/window_manager.dart';

class WindowService extends GetxService with WindowListener {
  // ignore: unused_field
  final _storage = GetStorage();

  @override
  Future<void> onInit() async {
    if (PlatformUtils.isDesktop) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        size: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
      windowManager.addListener(this);
    }
    super.onInit();
  }

  /// 窗口关闭时自动杀掉 yys.exe（pythonw.exe / python.exe）
  @override
  void onWindowClose() async {
    // 阻止关闭，先执行清理
    await windowManager.setPreventClose(true);
    try {
      await Process.run('taskkill', ['/f', '/t', '/im', 'pythonw.exe'],
          runInShell: false);
      await Process.run('taskkill', ['/f', '/t', '/im', 'python.exe'],
          runInShell: false);
    } catch (_) {}
    // 清理完成，允许关闭并销毁窗口
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}
