import 'dart:convert';
import 'package:http/http.dart' as http;

/// 卡密验证服务
/// 负责与卡密服务器通信，验证卡密有效性
class CardApiService {
  // 卡密服务器地址（直连 8001 端口，不经过 Nginx，与校知集完全隔离）
  static const String _baseUrl = 'http://42.192.108.177:8001';

  /// 验证卡密
  /// [cardKey] 卡密字符串，如 YYS-XXXX-XXXX-XXXX-XXXX
  /// [deviceId] 设备唯一标识
  /// [version] 客户端版本号
  /// 返回 CardVerifyResult
  Future<CardVerifyResult> verify({
    required String cardKey,
    required String deviceId,
    String version = '1.0.0',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/card/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_key': cardKey.toUpperCase(),
          'device_id': deviceId,
          'version': version,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return CardVerifyResult(
        success: data['success'] as bool? ?? false,
        message: data['message'] as String? ?? '未知错误',
        cardType: data['card_type'] as String?,
        expiresAt: data['expires_at'] as String?,
      );
    } catch (e) {
      return CardVerifyResult(
        success: false,
        message: '网络连接失败，请检查网络后重试',
      );
    }
  }

  /// 心跳检测
  Future<bool> heartbeat({
    required String cardKey,
    required String deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/card/heartbeat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_key': cardKey.toUpperCase(),
          'device_id': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 健康检查（测试服务器是否可达）
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// 卡密验证结果
class CardVerifyResult {
  final bool success;
  final String message;
  final String? cardType;
  final String? expiresAt;

  CardVerifyResult({
    required this.success,
    required this.message,
    this.cardType,
    this.expiresAt,
  });
}
