import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/login/login_controller.dart';

/// 登录页面
/// 支持邮箱验证码登录和密码登录两种方式
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildTabBar(controller),
                const SizedBox(height: 24),
                _buildForm(controller),
                const SizedBox(height: 16),
                _buildAgreement(controller),
                const SizedBox(height: 24),
                _buildLoginButton(controller),
                const SizedBox(height: 16),
                _buildRegisterLink(controller),
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
          '财务系统',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Windows 桌面版',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建Tab切换
  Widget _buildTabBar(LoginController controller) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              '验证码登录',
              controller.loginType.value == 'code',
              () => controller.loginType.value = 'code',
            ),
          ),
          Expanded(
            child: _buildTabItem(
              '密码登录',
              controller.loginType.value == 'password',
              () => controller.loginType.value = 'password',
            ),
          ),
        ],
      ),
    ));
  }

  /// 构建Tab项
  Widget _buildTabItem(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Theme.of(Get.context!).primaryColor : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建表单
  Widget _buildForm(LoginController controller) {
    return Column(
      children: [
        TextField(
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
        ),
        const SizedBox(height: 16),
        Obx(() => controller.loginType.value == 'code'
            ? _buildCodeInput(controller)
            : _buildPasswordInput(controller)),
      ],
    );
  }

  /// 构建验证码输入
  Widget _buildCodeInput(LoginController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.codeController,
            decoration: InputDecoration(
              labelText: '验证码',
              hintText: '请输入验证码',
              prefixIcon: const Icon(Icons.lock_outline),
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

  /// 构建密码输入
  Widget _buildPasswordInput(LoginController controller) {
    return Obx(() => TextField(
      controller: controller.passwordController,
      obscureText: !controller.showPassword.value,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '请输入密码',
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

  /// 构建协议勾选
  Widget _buildAgreement(LoginController controller) {
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

  /// 构建登录按钮
  Widget _buildLoginButton(LoginController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.login,
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
                '登 录',
                style: TextStyle(fontSize: 16),
              ),
      ),
    ));
  }

  /// 构建注册链接
  Widget _buildRegisterLink(LoginController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账号？',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: () => Get.toNamed('/register'),
          child: Text(
            '立即注册',
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
