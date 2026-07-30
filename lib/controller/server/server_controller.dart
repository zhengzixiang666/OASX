part of server;

class ServerController extends GetxController with LogMixin {
  final rootPathServer = ''.obs;
  final rootPathAuthenticated = true.obs;
  final showDeploy = true.obs;

  final log = ''.obs;
  final deployContent = ''.obs;
  Shell? shell;
  var shellController = ShellLinesController(encoding: utf8);

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

  Future<void> run() async {
    clearLog();

    // yys.exe 启动时会自动从配置文件读取 card_key，无需 OASX 写入
    // 直接用 Process.run 执行命令，避免 runInShell 弹出 cmd 黑窗
    try {
      final killResult = await Process.run(
        'taskkill',
        ['/f', '/t', '/im', 'pythonw.exe'],
        runInShell: false,
      );
      if (killResult.exitCode == 0) {
        addLog('INFO: 已终止 pythonw.exe');
      }
    } catch (_) {}
    try {
      final killResult = await Process.run(
        'taskkill',
        ['/f', '/t', '/im', 'python.exe'],
        runInShell: false,
      );
      if (killResult.exitCode == 0) {
        addLog('INFO: 已终止 python.exe');
      }
    } catch (_) {}
    // 使用 Process.start 启动 pythonw.exe（无窗口版，不弹控制台）
    try {
      final env = Map<String, String>.from(Platform.environment);
      env['PATH'] =
          '${rootPathServer.value},$pathGit,$pathPython,$pathAdb,$pathScripts';
      env['PYTHONUTF8'] = '1';
      env['PYTHONIOENCODING'] = 'utf-8';
      final process = await Process.start(
        '${rootPathServer.value}\\toolkit\\pythonw.exe',
        ['server.py'],
        workingDirectory: rootPathServer.value,
        mode: ProcessStartMode.normal,
        runInShell: false,
        environment: env,
      );
      process.stdout.transform(utf8.decoder).listen((data) {
        addLog(data);
      });
      process.stderr.transform(utf8.decoder).listen((data) {
        addLog(data);
      });
      addLog('INFO: yys.exe 已启动 (PID: ${process.pid})');
    } catch (e) {
      addLog('ERROR: 启动 yys.exe 失败: $e');
    }
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

}
