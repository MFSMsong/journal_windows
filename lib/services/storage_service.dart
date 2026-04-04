import 'package:shared_preferences/shared_preferences.dart';

/// 存储服务
class StorageService {
  static SharedPreferences? _prefs;
  
  // 存储键
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'userId';
  static const String _currentActivityIdKey = 'currentActivityId';
  static const String _userInfoKey = 'userInfo';

  /// 初始化
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 获取Token
  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  /// 设置Token
  static Future<void> setToken(String token) async {
    await _prefs?.setString(_tokenKey, token);
  }

  /// 清除Token
  static Future<void> clearToken() async {
    await _prefs?.remove(_tokenKey);
  }

  /// 获取用户ID
  static String? getUserId() {
    return _prefs?.getString(_userIdKey);
  }

  /// 设置用户ID
  static Future<void> setUserId(String userId) async {
    await _prefs?.setString(_userIdKey, userId);
  }

  /// 获取当前账本ID
  static String? getCurrentActivityId() {
    return _prefs?.getString(_currentActivityIdKey);
  }

  /// 设置当前账本ID
  static Future<void> setCurrentActivityId(String activityId) async {
    await _prefs?.setString(_currentActivityIdKey, activityId);
  }

  /// 清除当前账本ID
  static Future<void> removeCurrentActivityId() async {
    await _prefs?.remove(_currentActivityIdKey);
  }

  /// 获取用户信息JSON
  static String? getUserInfoJson() {
    return _prefs?.getString(_userInfoKey);
  }

  /// 设置用户信息JSON
  static Future<void> setUserInfoJson(String userInfoJson) async {
    await _prefs?.setString(_userInfoKey, userInfoJson);
  }

  /// 清除所有数据
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }

  /// 检查是否已登录
  static bool isLoggedIn() {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }
}
