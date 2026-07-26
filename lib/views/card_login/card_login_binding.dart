part of card_login;

/// 卡密登录页的依赖绑定
class CardLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CardLoginController());
  }
}
