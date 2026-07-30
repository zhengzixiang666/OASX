part of login;


class LoginController extends GetxController {
  static bool logined = false;
  var address = ''.obs;

  @override
  Future<void> onInit() async {
    // 用户版固定本机地址，自动连接
    address.value = '127.0.0.1:22288';

    if (!logined) {
      logined = true;
      await login(address.value);
    }
    super.onInit();
  }

  Future<void> login(String address) async {
    ApiClient().setAddress('http://$address');
    if (await ApiClient().testAddress()) {
      Get.offAllNamed('/main');
    } else {
      Get.snackbar('连接失败', '无法连接到 yys.exe，请点击右下角按钮启动服务',
          duration: const Duration(seconds: 4));
    }
  }
}
