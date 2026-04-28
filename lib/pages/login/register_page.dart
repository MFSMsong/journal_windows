import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/login/register_controller.dart';

/// 注册页面
/// 用户通过邮箱和密码注册账号
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RegisterController());

    return Scaffold(
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildForm(controller),
                const SizedBox(height: 16),
                _buildAgreement(controller),
                const SizedBox(height: 24),
                _buildRegisterButton(controller),
                const SizedBox(height: 16),
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '注册账号',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '创建您的好享记账账号',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建表单
  Widget _buildForm(RegisterController controller) {
    return Column(
      children: [
        _buildEmailInput(controller),
        const SizedBox(height: 16),
        _buildPasswordInput(controller),
        const SizedBox(height: 16),
        _buildConfirmPasswordInput(controller),
        const SizedBox(height: 16),
        _buildCodeInput(controller),
      ],
    );
  }

  /// 构建邮箱输入
  Widget _buildEmailInput(RegisterController controller) {
    return TextField(
      controller: controller.emailController,
      decoration: InputDecoration(
        labelText: '邮箱',
        hintText: '请输入邮箱地址',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  /// 构建密码输入
  Widget _buildPasswordInput(RegisterController controller) {
    return Obx(() => TextField(
      controller: controller.passwordController,
      obscureText: !controller.showPassword.value,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '6-20位字母数字组合',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            controller.showPassword.value 
                ? Icons.visibility_off 
                : Icons.visibility,
          ),
          onPressed: () => controller.showPassword.value = !controller.showPassword.value,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ));
  }

  /// 构建确认密码输入
  Widget _buildConfirmPasswordInput(RegisterController controller) {
    return Obx(() => TextField(
      controller: controller.confirmPasswordController,
      obscureText: !controller.showConfirmPassword.value,
      decoration: InputDecoration(
        labelText: '确认密码',
        hintText: '请再次输入密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            controller.showConfirmPassword.value 
                ? Icons.visibility_off 
                : Icons.visibility,
          ),
          onPressed: () => controller.showConfirmPassword.value = !controller.showConfirmPassword.value,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ));
  }

  /// 构建验证码输入
  Widget _buildCodeInput(RegisterController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.codeController,
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
        Obx(() => SizedBox(
          width: 110,
          height: 48,
          child: ElevatedButton(
            onPressed: controller.isSendingCode.value 
                ? null 
                : controller.sendCode,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              controller.countdown.value > 0
                  ? '${controller.countdown.value}s'
                  : '获取验证码',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        )),
      ],
    );
  }

  /// 构建协议勾选
  Widget _buildAgreement(RegisterController controller) {
    return Obx(() => Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: controller.isAgree.value,
            onChanged: (value) => controller.isAgree.value = value ?? false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            children: [
              const Text(
                '我已阅读并同意',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '《用户协议》',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
              ),
              const Text(
                '和',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '《隐私政策》',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  /// 构建注册按钮
  Widget _buildRegisterButton(RegisterController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.register,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '注 册',
                style: TextStyle(fontSize: 16),
              ),
      ),
    ));
  }

  /// 构建登录链接
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账号？',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Text(
            '立即登录',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(Get.context!).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
