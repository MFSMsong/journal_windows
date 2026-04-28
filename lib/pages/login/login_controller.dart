import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/services/storage_service.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/routers.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 登录控制器
/// 管理登录页面的状态和登录逻辑
/// 支持邮箱验证码登录和密码登录两种方式
class LoginController extends GetxController {
  /// 邮箱输入控制器
  final emailController = TextEditingController();
  
  /// 验证码输入控制器
  final codeController = TextEditingController();
  
  /// 密码输入控制器
  final passwordController = TextEditingController();
  
  /// 登录类型：code-验证码登录，password-密码登录
  final loginType = 'code'.obs;
  
  /// 是否同意协议
  final isAgree = false.obs;
  
  /// 是否正在加载
  final isLoading = false.obs;
  
  /// 是否正在发送验证码
  final isSendingCode = false.obs;
  
  /// 验证码倒计时
  final countdown = 0.obs;
  
  /// 是否显示密码
  final showPassword = false.obs;
  
  Timer? _timer;

  @override
  void onClose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
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
        ApiConfig.sendEmailCode(),
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

  /// 登录
  Future<void> login() async {
    final email = emailController.text.trim();
    
    if (!_validateEmail(email)) return;

    if (!isAgree.value) {
      ToastUtil.showInfo('请先同意用户协议');
      return;
    }
    
    if (loginType.value == 'code') {
      await _loginWithCode(email);
    } else {
      await _loginWithPassword(email);
    }
  }

  /// 验证码登录
  Future<void> _loginWithCode(String email) async {
    final code = codeController.text.trim();
    
    if (code.isEmpty) {
      ToastUtil.showInfo('请输入验证码');
      return;
    }
    
    isLoading.value = true;
    
    try {
      await HttpRequest.post(
        ApiConfig.login(),
        queryParameters: {
          'account': email,
          'code': code,
        },
        success: (data) async {
          final token = data as String;
          await StorageService.setToken(token);

          await UserService.to.getUserProfile();

          ToastUtil.showSuccess('登录成功');
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

  /// 密码登录
  Future<void> _loginWithPassword(String email) async {
    final password = passwordController.text.trim();
    
    if (password.isEmpty) {
      ToastUtil.showInfo('请输入密码');
      return;
    }
    
    isLoading.value = true;
    
    try {
      await HttpRequest.post(
        ApiConfig.loginWithPassword(),
        queryParameters: {
          'email': email,
          'password': password,
        },
        success: (data) async {
          final token = data as String;
          await StorageService.setToken(token);

          await UserService.to.getUserProfile();

          ToastUtil.showSuccess('登录成功');
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
