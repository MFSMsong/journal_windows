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
class LoginController extends GetxController {
  final accountController = TextEditingController();
  final codeController = TextEditingController();
  
  final loginType = 'phone'.obs;
  final isAgree = false.obs;
  final isLoading = false.obs;
  final isSendingCode = false.obs;
  final countdown = 0.obs;
  
  Timer? _timer;

  @override
  void onClose() {
    accountController.dispose();
    codeController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  /// 发送验证码
  Future<void> sendCode() async {
    final account = accountController.text.trim();
    
    if (!_validateAccount(account)) return;
    
    isSendingCode.value = true;
    
    try {
      final String url = loginType.value == 'phone'
          ? ApiConfig.sendSmsCode()
          : ApiConfig.sendEmailCode();
      
      final String paramName = loginType.value == 'phone' ? 'telephone' : 'email';
      
      await HttpRequest.post(
        url,
        queryParameters: {paramName: account},
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

  /// 验证账号
  bool _validateAccount(String account) {
    if (account.isEmpty) {
      ToastUtil.showInfo(loginType.value == 'phone' ? '请输入手机号' : '请输入邮箱');
      return false;
    }

    if (loginType.value == 'phone') {
      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(account)) {
        ToastUtil.showInfo('手机号格式不正确');
        return false;
      }
    } else {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(account)) {
        ToastUtil.showInfo('邮箱格式不正确');
        return false;
      }
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
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    
    if (!_validateAccount(account)) return;
    
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
        ApiConfig.login(),
        queryParameters: {
          'account': account,
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
}