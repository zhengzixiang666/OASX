library login;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/services/card_api_service.dart';
import 'package:oasx/services/device_service.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/utils/platform_utils.dart';

part './login_binding.dart';
part '../../controller/login/login_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context, isCollapsed: false),
      floatingActionButton: PlatformUtils.isWindows ? _serverButton() : null,
      body: _login(context),
    );
  }

  Widget _login(BuildContext context) {
    List<double> maxWidthHigh = switch (Theme.of(context).platform) {
      TargetPlatform.windows => [400, 500],
      TargetPlatform.linux => [400, 500],
      TargetPlatform.macOS => [400, 500],
      _ => [],
    };
    return FormBuilder(
      key: _formKey,
      child: <Widget>[
        _title(context),
        _cardKey(),
        _address(),
        _username(),
        _password(),
        _cardError(),
        _signin()
      ].toColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center),
    )
        .padding(vertical: 10)
        .constrained(
            maxHeight: maxWidthHigh.isNotEmpty ? maxWidthHigh[0] : 500,
            maxWidth: maxWidthHigh.isNotEmpty ? maxWidthHigh[1] : 400)
        .alignment(Alignment.center);
  }

  Widget _title(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Icon(
      Icons.verified_user_rounded,
      size: 48,
      color: theme.colorScheme.primary,
    ).padding(bottom: 8);
  }

  Widget _cardKey() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'card_key',
      initialValue: loginController.cardKey.value,
      decoration: const InputDecoration(
        labelText: '卡密',
        hintText: 'YYS-XXXX-XXXX-XXXX-XXXX',
        prefixIcon: Icon(Icons.key_rounded),
      ),
    ).padding(horizontal: 20, top: 5);
  }

  Widget _address() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'address',
      initialValue: loginController.address.value,
      decoration: const InputDecoration(labelText: 'Address'),
    ).padding(horizontal: 20, top: 20);
  }

  Widget _username() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'username',
      initialValue: loginController.username.value,
      decoration: const InputDecoration(labelText: 'Username'),
    ).padding(horizontal: 20, top: 20);
  }

  Widget _password() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'password',
      initialValue: loginController.password.value,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
    ).padding(horizontal: 20, top: 20);
  }

  Widget _cardError() {
    return Obx(() {
      final c = Get.find<LoginController>();
      if (c.cardError.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.cardError.value,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _signin() {
    LoginController loginController = Get.find<LoginController>();
    return Obx(() {
      if (loginController.isVerifying.value) {
        return const Column(
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 12),
            Text('正在验证...', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ).padding(horizontal: 20, top: 40);
      }
      return ElevatedButton(
        onPressed: () async => {
          if (_formKey.currentState?.saveAndValidate() ?? false)
            {await loginController.toMain(data: _formKey.currentState!.value)}
        },
        child: const Text('Login'),
      ).padding(horizontal: 20, top: 40);
    });
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
