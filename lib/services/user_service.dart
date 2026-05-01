import 'dart:convert';
import 'package:get/get.dart';
import 'package:journal_windows/models/user.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/services/storage_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/charts_service.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/pages/expense/expense_list_controller.dart';

/// 用户服务
class UserService extends GetxService {
  static UserService get to => Get.find();
  
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;

  /// 初始化
  static Future<void> init() async {
    Get.put(UserService());
    await UserService.to._loadUserInfo();
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    final userInfoJson = StorageService.getUserInfoJson();
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      try {
        final json = jsonDecode(userInfoJson);
        currentUser.value = User.fromJson(json);
      } catch (e) {
        // ignore
      }
    }
  }

  /// 获取用户信息
  Future<User?> getUserProfile() async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getUserProfile(),
      );
      
      if (result != null) {
        final user = User.fromJson(result);
        currentUser.value = user;
        await StorageService.setUserInfoJson(jsonEncode(user.toJson()));
        await StorageService.setUserId(user.userId);
        return user;
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// 更新用户信息
  Future<void> updateUser(
    User user, {
    required Function(String) onSuccess,
    required Function(String) onFail,
  }) async {
    isLoading.value = true;
    try {
      await HttpRequest.request(
        Method.patch,
        ApiConfig.updateUserInfo(),
        params: user.toJson(),
        success: (data) {
          print('updateUser success: data=$data');
          currentUser.value = user;
          StorageService.setUserInfoJson(jsonEncode(user.toJson()));
          onSuccess('保存成功');
        },
        fail: (code, msg) {
          print('updateUser fail: code=$code, msg=$msg');
          onFail(msg.isNotEmpty ? msg : '保存失败，请重试(code: $code)');
        },
      );
    } catch (e) {
      print('更新用户信息失败: $e');
      onFail('保存失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 发送删除账户验证码
  Future<bool> sendDeleteAccountEmailCode() async {
    try {
      bool success = false;
      await HttpRequest.post<Map<String, dynamic>>(
        ApiConfig.sendDeleteAccountEmailCode(),
        success: (data) {
          success = true;
        },
        fail: (code, msg) {
          print('发送删除账户验证码失败: code=$code, msg=$msg');
        },
      );
      return success;
    } catch (e) {
      print('发送删除账户验证码失败: $e');
      return false;
    }
  }

  /// 删除用户账户
  Future<bool> deleteUser(String code) async {
    isLoading.value = true;
    try {
      bool success = false;
      await HttpRequest.delete<Map<String, dynamic>>(
        ApiConfig.deleteUser(),
        queryParameters: {'code': code},
        success: (data) {
          success = true;
        },
        fail: (code, msg) {
          print('删除用户失败: code=$code, msg=$msg');
        },
      );
      
      if (success) {
        await logout();
        return true;
      }
    } catch (e) {
      print('删除用户失败: $e');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  /// 登出
  Future<void> logout() async {
    try {
      await HttpRequest.post(
        ApiConfig.logout(),
        success: (_) {},
        fail: (_, __) {},
      );
    } catch (e) {
      // 忽略退出登录接口调用失败
    }
    
    currentUser.value = null;
    // 清理账本缓存，避免切换账号后显示错误的账本数据
    ActivityService.to.clearCache();
    // 清理账单服务缓存
    ExpenseService.to.clearCache();
    // 清理账单列表页面控制器缓存
    try {
      final expenseController = Get.find<ExpenseListController>();
      expenseController.clearCache();
    } catch (e) {
      // 如果控制器不存在则忽略
    }
    // 清理图表统计数据缓存
    ChartsService.to.clearCache();
    await StorageService.clearAll();
  }

  /// 检查是否已登录
  bool get isLoggedIn => StorageService.isLoggedIn();
}