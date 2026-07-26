import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart' hide MarkdownWidget;
import 'package:markdown_widget/markdown_widget.dart' show MarkdownWidget;
import 'package:url_launcher/url_launcher.dart';

import 'package:oasx/utils/logger.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/utils/check_version.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/api/home_model.dart';
import 'package:oasx/config/github_readme.dart' show githubReadme;

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 不再请求 GitHub API 获取 README，直接使用内置内容
    return MarkdownWidget(data: githubReadme).paddingAll(10);
  }

  // 更新检查已禁用（自定义构建版本，不检查原仓库更新）
  Future<void> checkUpdate() async {
    return;
  }
}
