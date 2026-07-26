import 'package:get/get.dart';

import 'package:oasx/views/layout/layout.dart';
import 'package:oasx/views/layout/binding.dart';
import 'package:oasx/views/login/login_view.dart';
import 'package:oasx/views/card_login/card_login_view.dart';
import 'package:oasx/views/settings/settings_view.dart';
import 'package:oasx/views/server/server_view.dart';

class Routes {
  /// 应用启动后第一个显示的页面 —— 卡密登录页
  static const initial = '/card-login';

  static final routes = [
    // 卡密登录页（入口）
    GetPage(
      name: '/card-login',
      page: () => CardLoginView(),
      binding: CardLoginBinding(),
    ),
    // 服务器连接登录页
    GetPage(
      name: '/login',
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: '/main',
      page: () => const LayoutView(),
      binding: LayoutBinding(),
    ),
    GetPage(
      name: '/settings',
      page: () => SettingsView(),
    ),
    GetPage(
      name: '/server',
      page: () => const ServerView(),
      binding: BindingsBuilder(() {
        Get.put<ServerController>(ServerController());
      }),
    ),
  ];
}
