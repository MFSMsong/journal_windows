import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 密码设置/修改对话框
/// 用于用户设置密码或修改密码
class PasswordDialog extends StatefulWidget {
  /// 是否已设置密码（true=修改密码，false=设置密码）
  final bool hasPassword;

  const PasswordDialog({super.key, required this.hasPassword});

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();
  
  bool isLoading = false;
  bool isSendingCode = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  int countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// 发送验证码
  Future<void> _sendCode() async {
    final user = UserService.to.currentUser.value;
    if (user == null || user.email == null) {
      ToastUtil.showError('用户邮箱信息不完整');
      return; 
    }

    setState(() => isSendingCode = true);

    try {
      await HttpRequest.post(
        ApiConfig.sendPasswordEmailCode(),
        queryParameters: {'email': user.email},
        success: (_) {
          ToastUtil.showSuccess('验证码已发送');
          _startCountdown();
        },
        fail: (code, msg) {
          ToastUtil.showError(msg);
        },
      );
    } finally {
      setState(() => isSendingCode = false);
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    setState(() => countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => countdown--);
      if (countdown <= 0) {
        timer.cancel();
      }
    });
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

  /// 提交
  Future<void> _submit() async {
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final code = codeController.text.trim();

    if (!_validatePassword(password)) return;

    if (confirmPassword.isEmpty) {
      ToastUtil.showInfo('请确认密码');
      return;
    }

    if (password != confirmPassword) {
      ToastUtil.showInfo('两次输入的密码不一致');
      return;
    }

    if (widget.hasPassword && code.isEmpty) {
      ToastUtil.showInfo('请输入验证码');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (widget.hasPassword) {
        await _updatePassword(code, password);
      } else {
        await _setPassword(password);
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 设置密码
  Future<void> _setPassword(String password) async {
    await HttpRequest.post(
      ApiConfig.setPassword(),
      queryParameters: {'password': password},
      success: (_) {
        ToastUtil.showSuccess('密码设置成功');
        Get.back(result: true);
      },
      fail: (code, msg) {
        ToastUtil.showError(msg);
      },
    );
  }

  /// 修改密码
  Future<void> _updatePassword(String code, String newPassword) async {
    await HttpRequest.post(
      ApiConfig.updatePassword(),
      queryParameters: {
        'code': code,
        'newPassword': newPassword,
      },
      success: (_) {
        ToastUtil.showSuccess('密码修改成功');
        Get.back(result: true);
      },
      fail: (code, msg) {
        ToastUtil.showError(msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasPassword ? '修改密码' : '设置密码'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.hasPassword) ...[
              Text(
                '修改密码需要先验证邮箱',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      decoration: InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入验证码',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSendingCode || countdown > 0 ? null : _sendCode,
                      child: Text(
                        countdown > 0 ? '${countdown}s' : '获取验证码',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                labelText: '新密码',
                hintText: '6-20位字母数字组合',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: '确认密码',
                hintText: '请再次输入密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确定'),
        ),
      ],
    );
  }
}
