library server;

import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/component/log/log_widget.dart';
import 'package:process_run/shell.dart';
import 'dart:io';
import 'package:styled_widget/styled_widget.dart';
import 'package:code_editor/code_editor.dart';

import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/controller/settings.dart';

part './deploy_view.dart';
part '../../controller/server/server_controller.dart';

class ServerView extends StatelessWidget {
  const ServerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildPlatformAppBar(context, isCollapsed: false),
      floatingActionButton: startServerButton(),
      body: _body(),
    );
  }

  Widget _body() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      ServerController serverController = Get.find<ServerController>();
      return SingleChildScrollView(
          child: Column(
        spacing: 6,
        children: [
          ExpansionTileGroup(
            toggleType: ToggleType.expandOnlyCurrent,
            children: [
              path(context),
              repoSelector(context),
              deploy(constraints.maxHeight - 200, context),
            ],
          ),
          LogWidget(
                  key: ValueKey(serverController.hashCode),
                  controller: serverController,
                  title: I18n.setup_log.tr)
              .constrained(height: constraints.maxHeight - 200)
        ],
      ).padding(right: 10, left: 10));
    });
  }

  ExpansionTileItem path(BuildContext context) {
    Widget path = GetX<ServerController>(builder: (controller) {
      return <Widget>[
        Text(I18n.root_path_server.tr,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(
          width: 10,
        ),
        Text(controller.rootPathServer.value),
        TextButton(
            onPressed: () async {
              String? selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory == null) {
                // User canceled the picker
                return;
              }
              controller.updateRootPathServer(selectedDirectory);
            },
            child: Text(I18n.select_root_path_server.tr))
      ].toRow();
    });
    Widget pass = GetX<ServerController>(builder: (controller) {
      return <Widget>[
        controller.rootPathAuthenticated.value
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.red),
        Text(
          controller.rootPathAuthenticated.value
              ? I18n.root_path_correct.tr
              : I18n.root_path_incorrect.tr,
          // style: Theme.of(context).textTheme.titleMedium
        ),
      ].toRow();
    });

    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: pass,
      children: [
        path,
        Text(I18n.root_path_server_help.tr),
      ],
    );
  }

  ExpansionTileItem repoSelector(BuildContext context) {
    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: Text('仓库切换',
          style: Theme.of(context).textTheme.titleMedium),
      children: [
        GetX<ServerController>(builder: (controller) {
          if (!controller.rootPathAuthenticated.value) {
            return const Text('请先设置正确的 OAS 根目录');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 当前仓库信息
              if (controller.currentRepoUrl.value.isNotEmpty) ...[
                Text('当前仓库:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(controller.safeRepoUrl,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                Text('分支: ${controller.currentBranch.value}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                const SizedBox(height: 8),
              ],
              // 预设列表
              ...ServerController.repoPresets.map((preset) {
                var isActive = controller.selectedPreset.value == preset['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.grey[300]!,
                      width: isActive ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isActive ? Colors.green.withOpacity(0.05) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isActive ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(preset['name']!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                if (isActive)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  ),
                              ],
                            ),
                            Text(preset['desc']!,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      if (!isActive)
                        TextButton(
                          onPressed: () => controller.switchRepo(preset['id']!),
                          child: const Text('切换', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              Text('切换后点击右下角按钮重启服务即可生效',
                  style: TextStyle(fontSize: 11, color: Colors.orange[700])),
            ],
          );
        }),
      ],
    );
  }

  ExpansionTileItem deploy(double maxHeight, BuildContext context) {
    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      collapsedBackgroundColor:
          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.24),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      title: Text(I18n.setup_deploy.tr,
          style: Theme.of(context).textTheme.titleMedium),
      children: [
        SingleChildScrollView(
          child: code(maxHeight - 50),
        ).constrained(height: maxHeight)
      ],
    );
  }

  Widget startServerButton() {
    return GetX<ServerController>(builder: (controller) {
      if (controller.rootPathAuthenticated.value) {
        return FloatingActionButton(
            child: const Icon(Icons.auto_mode_rounded),
            onPressed: () {
              controller.run();
            });
      } else {
        return const SizedBox(
          width: 100,
          height: 100,
        );
      }
    });
  }

  Widget code(double maxHeight) {
    return GetX<ServerController>(builder: (controller) {
      FileEditor file = FileEditor(
        name: "deploy.yaml",
        language: "yaml",
        code: controller.deployContent.value, // [code] needs a string
      );
      EditorModel model = EditorModel(
        files: [file], // the files created above
        // you can customize the editor as you want
        styleOptions: EditorModelStyleOptions(
          heightOfContainer: maxHeight,
          // theme: githubTheme,
        ),
      );
      return CodeEditor(
        model: model,
        formatters: const ["yaml"],
        onSubmit: (String language, String value) {
          controller.writeDeploy(value);
        },
      );
    });
  }
}
