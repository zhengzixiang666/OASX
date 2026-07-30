part of login;


class LoginController extends GetxController {
  static bool logined = false;
  var username = ''.obs;
  var password = ''.obs;
  var address = ''.obs;
  var cardKey = ''.obs;
  var isVerifying = false.obs;
  var cardError = ''.obs;

  GetStorage storage = GetStorage();

  @override
  Future<void> onInit() async {
    username.value = storage.read(StorageKey.username.name) ?? "";
    password.value = storage.read(StorageKey.password.name) ?? "";
    address.value = storage.read(StorageKey.address.name) ?? "";
    cardKey.value = storage.read('card_key') ?? "";

    // 不再自动登录，让用户手动点 Login
    super.onInit();
  }

  /// 进入主页面（先验证卡密，再连接服务器）
  Future<void> toMain({required Map<String, dynamic> data}) async {
    cardError.value = '';
    isVerifying.value = true;

    final card = (data['card_key'] ?? '').toString().trim();
    final addr = (data['address'] ?? '').toString().trim();

    // 1. 验证卡密
    if (card.isEmpty) {
      cardError.value = '请输入卡密';
      isVerifying.value = false;
      return;
    }

    final deviceId = DeviceService.getDeviceId();
    final api = CardApiService();
    final result = await api.verify(cardKey: card, deviceId: deviceId);

    if (!result.success) {
      cardError.value = result.message;
      isVerifying.value = false;
      return;
    }

    // 卡密验证通过，保存
    storage.write('card_key', card);
    storage.write('card_verified', true);
    cardKey.value = card;

    // 2. 连接服务器
    storage.write(StorageKey.username.name, data['username']);
    storage.write(StorageKey.password.name, data['password']);
    storage.write(StorageKey.address.name, data['address']);
    printInfo(info: data.toString());
    await login(data['address']);
    isVerifying.value = false;
  }

  Future<void> login(String address) async {
    ApiClient().setAddress('http://$address');
    if (await ApiClient().testAddress()) {
      Get.offAllNamed('/main');
    } else {
      Get.snackbar('连接失败', '无法连接到 yys.exe，请先在「服务器」页面启动服务',
          duration: const Duration(seconds: 4));
    }
  }
}
