library card_login;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/services/card_api_service.dart';
import 'package:oasx/services/device_service.dart';

part './card_login_binding.dart';
part '../../controller/card_login/card_login_controller.dart';

/// 卡密登录页面
/// 用户启动 OASX 后第一个看到的页面
/// 输入卡密 → 联网验证 → 通过后进入服务器连接页
class CardLoginView extends StatelessWidget {
  CardLoginView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardLoginController>();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return _loadingView();
        }
        return _loginForm(context, controller);
      }),
    );
  }

  /// 加载中视图
  Widget _loadingView() {
    return Center(
      child: <Widget>[
        const CircularProgressIndicator(strokeWidth: 3),
        const SizedBox(height: 20),
        Text(
          '正在验证卡密...',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ].toColumn(mainAxisAlignment: MainAxisAlignment.center),
    );
  }

  /// 卡密输入表单
  Widget _loginForm(BuildContext context, CardLoginController controller) {
    ThemeData theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(32),
        child: FormBuilder(
          key: _formKey,
          child: <Widget>[
            // Logo / 标题
            Icon(
              Icons.verified_user_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'YYS 脚本助手',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请输入卡密以激活使用',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),

            // 卡密输入框
            FormBuilderTextField(
              name: 'card_key',
              initialValue: controller.cardKey.value,
              decoration: InputDecoration(
                labelText: '卡密',
                hintText: 'YYS-XXXX-XXXX-XXXX-XXXX',
                prefixIcon: const Icon(Icons.key_rounded),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入卡密';
                }
                if (value.trim().length < 10) {
                  return '卡密格式不正确';
                }
                return null;
              },
            ),

            // 错误提示
            Obx(() {
              if (controller.errorMsg.value.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                          controller.errorMsg.value,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 24),

            // 验证按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    await controller.verify(
                      _formKey.currentState!.value['card_key'],
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '激活',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 卡密信息（验证成功后显示）
            Obx(() {
              if (controller.verifyResult.value != null &&
                  controller.verifyResult.value!.success) {
                final r = controller.verifyResult.value!;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: <Widget>[
                    Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '验证通过，即将进入...',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.expiresAt != null)
                      Text(
                        '有效期至: ${r.expiresAt}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 12,
                        ),
                      ),
                  ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
                );
              }
              return const SizedBox.shrink();
            }),

            const SizedBox(height: 24),

            // 底部信息
            Text(
              '卡密获取请联系卖家 | 设备ID: ${controller.deviceId.substring(0, 8)}...',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ].toColumn(crossAxisAlignment: CrossAxisAlignment.stretch),
        ),
      ),
    );
  }
}
