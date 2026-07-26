part of card_login;

/// 卡密登录控制器
/// 管理卡密验证状态、本地缓存、心跳检测
class CardLoginController extends GetxController {
  static const String _storageCardKey = 'card_key';
  static const String _storageVerifiedKey = 'card_verified';

  final CardApiService _api = CardApiService();

  var cardKey = ''.obs;
  var deviceId = '';
  var isLoading = false.obs;
  var errorMsg = ''.obs;
  var verifyResult = Rxn<CardVerifyResult>();

  Timer? _heartbeatTimer;

  GetStorage storage = GetStorage();

  @override
  Future<void> onInit() async {
    deviceId = DeviceService.getDeviceId();

    // 读取缓存的卡密
    cardKey.value = storage.read(_storageCardKey) ?? '';

    // 如果之前已验证通过，直接跳过
    bool? verified = storage.read(_storageVerifiedKey);
    if (verified == true && cardKey.value.isNotEmpty) {
      // 后台静默验证，通过则直接跳转
      _silentVerify();
    }

    super.onInit();
  }

  /// 静默验证（自动登录）
  Future<void> _silentVerify() async {
    isLoading.value = true;
    final result = await _api.verify(
      cardKey: cardKey.value,
      deviceId: deviceId,
    );

    if (result.success) {
      _onVerifySuccess(result);
    } else {
      // 静默验证失败，不显示错误，让用户手动验证
      isLoading.value = false;
      storage.write(_storageVerifiedKey, false);
    }
  }

  /// 用户手动验证
  Future<void> verify(String inputKey) async {
    errorMsg.value = '';
    isLoading.value = true;
    verifyResult.value = null;

    final key = inputKey.trim();
    if (key.isEmpty) {
      errorMsg.value = '请输入卡密';
      isLoading.value = false;
      return;
    }

    final result = await _api.verify(
      cardKey: key,
      deviceId: deviceId,
    );

    verifyResult.value = result;

    if (result.success) {
      // 保存卡密到本地
      cardKey.value = key;
      storage.write(_storageCardKey, key);
      storage.write(_storageVerifiedKey, true);
      _onVerifySuccess(result);
    } else {
      errorMsg.value = result.message;
      isLoading.value = false;
    }
  }

  /// 验证成功后的处理
  void _onVerifySuccess(CardVerifyResult result) {
    // 延迟 1.5 秒后跳转到服务器登录页
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offAllNamed('/login');
    });

    // 启动心跳定时器（每 30 分钟）
    _startHeartbeat();
  }

  /// 启动心跳检测
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) async {
        final ok = await _api.heartbeat(
          cardKey: cardKey.value,
          deviceId: deviceId,
        );
        if (!ok) {
          // 心跳失败，可能卡密被禁用或过期
          _heartbeatTimer?.cancel();
          storage.write(_storageVerifiedKey, false);
          // 强制回到卡密登录页
          Get.offAllNamed('/card-login');
        }
      },
    );
  }

  @override
  void onClose() {
    _heartbeatTimer?.cancel();
    super.onClose();
  }
}
