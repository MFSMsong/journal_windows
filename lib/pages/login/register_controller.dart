import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/services/storage_service.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/routers.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 注册控制器
/// 管理注册页面的状态和注册逻辑
class RegisterController extends GetxController {
  /// 邮箱输入控制器
  final emailController = TextEditingController();
  
  /// 密码输入控制器
  final passwordController = TextEditingController();
  
  /// 确认密码输入控制器
  final confirmPasswordController = TextEditingController();
  
  /// 验证码输入控制器
  final codeController = TextEditingController();
  
  /// 是否正在加载
  final isLoading = false.obs;
  
  /// 是否正在发送验证码
  final isSendingCode = false.obs;
  
  /// 验证码倒计时
  final countdown = 0.obs;
  
  /// 是否显示密码
  final showPassword = false.obs;
  
  /// 是否显示确认密码
  final showConfirmPassword = false.obs;
  
  /// 是否同意协议
  final isAgree = false.obs;
  
  Timer? _timer;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  /// 发送验证码
  Future<void> sendCode() async {
    final email = emailController.text.trim();
    
    if (!_validateEmail(email)) return;
    
    isSendingCode.value = true;
    
    try {
      await HttpRequest.post(
        ApiConfig.sendRegisterEmailCode(),
        queryParameters: {'email': email},
        success: (_) {
          ToastUtil.showSuccess('验证码已发送');
          _startCountdown();
        },
        fail: (code, msg) {
          ToastUtil.showError(msg);
        },
      );
    } finally {
      isSendingCode.value = false;
    }
  }

  /// 验证邮箱格式
  bool _validateEmail(String email) {
    if (email.isEmpty) {
      ToastUtil.showInfo('请输入邮箱');
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ToastUtil.showInfo('邮箱格式不正确');
      return false;
    }

    return true;
  }

  /// 验证密码格式
  bool _validatePassword(String password) {
    if (password.isEmpty) {
      ToastUtil.showInfo('请输入密码');
      return false;
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{6,20}$').hasMatch(password)) {
      ToastUtil.showInfo('密码格式错误，需6-20位字母数字组合');
      return false;
    }

    return true;
  }

  /// 开始倒计时
  void _startCountdown() {
    countdown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown.value--;
      if (countdown.value <= 0) {
        timer.cancel();
      }
    });
  }

  /// 注册
  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final code = codeController.text.trim();
    
    if (!_validateEmail(email)) return;
    
    if (!_validatePassword(password)) return;
    
    if (confirmPassword.isEmpty) {
      ToastUtil.showInfo('请确认密码');
      return;
    }
    
    if (password != confirmPassword) {
      ToastUtil.showInfo('两次输入的密码不一致');
      return;
    }
    
    if (code.isEmpty) {
      ToastUtil.showInfo('请输入验证码');
      return;
    }

    if (!isAgree.value) {
      ToastUtil.showInfo('请先同意用户协议');
      return;
    }
    
    isLoading.value = true;
    
    try {
      await HttpRequest.post(
        ApiConfig.register(),
        queryParameters: {
          'email': email,
          'password': password,
          'code': code,
        },
        success: (data) async {
          final token = data as String;
          await StorageService.setToken(token);

          await UserService.to.getUserProfile();

          ToastUtil.showSuccess('注册成功');
          Get.offAllNamed(Routers.LayoutPageUrl);
        },
        fail: (code, msg) {
          ToastUtil.showError(msg);
        },
      );
    } finally {
      isLoading.value = false;
    }
  }
}
