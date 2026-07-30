library login;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/utils/platform_utils.dart';

part './login_binding.dart';
part '../../controller/login/login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context, isCollapsed: false),
      floatingActionButton: PlatformUtils.isWindows ? _serverButton() : null,
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return <Widget>[
      // 自动连接动画
      const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
      const SizedBox(height: 20),
      Text(
        '正在连接服务器...',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '如果长时间无响应，请点击右下角按钮启动服务',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    ].toColumn(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
    ).alignment(Alignment.center);
  }

  Widget _serverButton() {
    return FloatingActionButton(
        heroTag: 'SERVER',
        child: const Icon(Icons.developer_board_rounded),
        onPressed: () {
          Get.toNamed('/server');
        });
  }
}
