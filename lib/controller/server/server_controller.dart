part of server;

class ServerController extends GetxController with LogMixin {
  final rootPathServer = ''.obs;
  final rootPathAuthenticated = true.obs;
  final showDeploy = true.obs;

  final log = ''.obs;
  final deployContent = ''.obs;
  Shell? shell;
  var shellController = ShellLinesController(encoding: utf8);

  // 仓库切换状态
  final currentRepoUrl = ''.obs;
  final currentBranch = ''.obs;
  final selectedPreset = ''.obs;

  // 预设仓库列表
  static const repoPresets = <Map<String, String>>[
    {
      'id': 'my_gitee',
      'name': '我的 Gitee（自有仓库）',
      'url': 'https://zhengzixiang0314:0c1e3b89cca23a74ed7d7e06ed4fb3c3@gitee.com/zhengzixiang0314/yys-script.git',
      'branch': 'master',
      'desc': '自有仓库，国内直连，带卡密验证',
    },
    {
      'id': 'thirdparty_gitee',
      'name': '第三方 Gitee（原版）',
      'url': 'https://gitee.com/pattering-rain/yys.git',
      'branch': 'run_now',
      'desc': '第三方维护的原版脚本',
    },
    {
      'id': 'my_github',
      'name': '我的 GitHub（备份）',
      'url': 'https://github.com/zhengzixiang666/yys-script.git',
      'branch': 'master',
      'desc': 'GitHub 备份，需要代理',
    },
  ];

  @override
  void onInit() {
    rootPathServer.value =
        Get.find<SettingsController>().storage.read('rootPathServer') ??
            'Please set OAS root path';
    shell = getShell;
    shellController.stream.listen((event) {
      addLog('INFO: $event');
    });
    rootPathAuthenticated.value = authenticatePath(rootPathServer.value);
    if (rootPathAuthenticated.value) {
      readDeploy();
      loadRepoInfo();
    }
    super.onInit();
  }

  void updateRootPathServer(String value) {
    if (authenticatePath(value)) {
      rootPathAuthenticated.value = true;
    } else {
      rootPathAuthenticated.value = false;
    }
    // value = value.replaceAll('\\', '\\\\');
    rootPathServer.value = value;
    shell = getShell;
    Get.find<SettingsController>()
        .storage
        .write('rootPathServer', rootPathServer.value);
    if (rootPathAuthenticated.value) {
      readDeploy();
      loadRepoInfo();
    }
  }

  bool authenticatePath(String root) {
    root.replaceAll('\\', '/');
    try {
      // 先是判断根目录
      Directory rootDir = Directory(root);
      if (!rootDir.existsSync()) {
        return false;
      }
      // 然后是判断python是否存在
      File python = File('${rootDir.path}/toolkit/python.exe');
      if (!python.existsSync()) {
        return false;
      }
      // 然后判断git是否存在
      File git = File('${rootDir.path}/toolkit/Git/cmd/git.exe');
      if (!git.existsSync()) {
        return false;
      }
      // 然后判断安装器是否存在
      File installer = File('${rootDir.path}/deploy/installer.py');
      if (!installer.existsSync()) {
        return false;
      }
      // 然后判断deploy是否存在
      File deploy = File('${rootDir.path}/config/deploy.yaml');
      if (!deploy.existsSync()) {
        return false;
      }
    } catch (e) {
      printError(info: e.toString());
      return false;
    }

    return true;
  }

  String get pathGit => '${rootPathServer.value}\\toolkit\\Git\\mingw64\\bin"';
  String get pathPython => '${rootPathServer.value}\\toolkit';
  String get pathAdb =>
      '${rootPathServer.value}\\toolkit\\Lib\\site-packages\\adbutils\\binaries';
  String get pathScripts => '${rootPathServer.value}\\toolkit\\Scripts';
  Map<String, String> get pathPATH => {
        'PATH':
            '${rootPathServer.value},$pathGit,$pathPython,$pathAdb,$pathScripts',
        'PYTHONUTF8': '1',
        'PYTHONIOENCODING': 'utf-8',
      };
  Shell get getShell => Shell(
        workingDirectory: rootPathServer.value,
        runInShell: true,
        environment: pathPATH,
        stdout: shellController.sink,
        verbose: false,
      );

  Future<void> runShell(String command) async {
    try {
      var result = await shell!.run(command);
      printInfo(info: result.errText);
    } on ShellException catch (e) {
      addLog('ERROR: ${e.toString()}');
    }
  }

  void run() {
    clearLog();
    shell!.kill();
    runShell('echo OAS working directory: ').then((value) => null);
    runShell('pwd').then((value) => null);
    runShell('python -m deploy.installer').then((value) => null);
    runShell('echo Start OAS').then((value) => null);
    runShell('taskkill /f /t /im pythonw.exe').then((value) => null);
    runShell(".\\toolkit\\pythonw.exe  server.py").then((value) => null);
  }

  void readDeploy() {
    String filePath = '${rootPathServer.value}\\config\\deploy.yaml';
    try {
      File file = File(filePath);
      if (file.existsSync()) {
        deployContent.value = file.readAsStringSync();
        return;
      } else {
        deployContent.value = 'File not found';
        return;
      }
    } catch (e) {
      deployContent.value = 'Error reading file: $e';
      return;
    }
  }

  void writeDeploy(String value) {
    String filePath = '${rootPathServer.value}\\config\\deploy.yaml';
    deployContent.value = value;
    try {
      File file = File(filePath);
      if (file.existsSync()) {
        file.writeAsStringSync(deployContent.value);
        return;
      } else {
        deployContent.value = 'File not found';
        return;
      }
    } catch (e) {
      deployContent.value = 'Error writing file: $e';
      return;
    }
  }

  /// 从 deployContent 解析当前仓库地址和分支
  void loadRepoInfo() {
    if (deployContent.value.isEmpty ||
        deployContent.value == 'File not found') return;

    currentRepoUrl.value = '';
    currentBranch.value = '';
    for (var line in deployContent.value.split('\n')) {
      var trimmed = line.trim();
      if (trimmed.startsWith('Repository:')) {
        currentRepoUrl.value =
            trimmed.substring('Repository:'.length).trim();
      } else if (trimmed.startsWith('Branch:')) {
        currentBranch.value = trimmed.substring('Branch:'.length).trim();
      }
    }

    // 匹配预设
    selectedPreset.value = '';
    for (var preset in repoPresets) {
      if (currentRepoUrl.value.contains(preset['url']!) ||
          preset['url']!.contains(currentRepoUrl.value)) {
        if (currentBranch.value == preset['branch']) {
          selectedPreset.value = preset['id']!;
          break;
        }
      }
    }
  }

  /// 切换到指定预设仓库，修改 deploy.yaml
  void switchRepo(String presetId) {
    var preset = repoPresets.firstWhere(
      (p) => p['id'] == presetId,
      orElse: () => <String, String>{},
    );
    if (preset.isEmpty) return;

    var lines = deployContent.value.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var trimmed = lines[i].trim();
      if (trimmed.startsWith('Repository:')) {
        var indent = lines[i].substring(
            0, lines[i].length - lines[i].trimLeft().length);
        lines[i] = '$indent Repository: ${preset['url']}';
      } else if (trimmed.startsWith('Branch:')) {
        var indent = lines[i].substring(
            0, lines[i].length - lines[i].trimLeft().length);
        lines[i] = '$indent Branch: ${preset['branch']}';
      }
    }
    var newContent = lines.join('\n');
    writeDeploy(newContent);
    loadRepoInfo();
    addLog('INFO: 仓库已切换为 ${preset['name']}，重启服务后生效');
  }

  /// 隐藏 URL 中的 token，用于 UI 显示
  String get safeRepoUrl {
    var url = currentRepoUrl.value;
    if (url.contains('@')) {
      url = url.replaceAllMapped(
        RegExp(r'https://[^@]+@'), (m) => 'https://');
    }
    return url;
  }
}
