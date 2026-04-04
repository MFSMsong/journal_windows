import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/login/login_controller.dart';

/// 登录页面
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              _buildTabBar(controller),
              const SizedBox(height: 24),
              Obx(() => _buildForm(controller)),
              const SizedBox(height: 16),
              _buildAgreement(controller),
              const SizedBox(height: 24),
              _buildLoginButton(controller),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
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
          '好享记账',
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
              '手机登录',
              controller.loginType.value == 'phone',
              () => controller.loginType.value = 'phone',
            ),
          ),
          Expanded(
            child: _buildTabItem(
              '邮箱登录',
              controller.loginType.value == 'email',
              () => controller.loginType.value = 'email',
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
        // 账号输入框
        TextField(
          controller: controller.accountController,
          decoration: InputDecoration(
            labelText: controller.loginType.value == 'phone' ? '手机号' : '邮箱',
            hintText: controller.loginType.value == 'phone' 
                ? '请输入手机号' 
                : '请输入邮箱地址',
            prefixIcon: Icon(
              controller.loginType.value == 'phone' 
                  ? Icons.phone_android 
                  : Icons.email_outlined,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: controller.loginType.value == 'phone'
              ? TextInputType.phone
              : TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // 验证码输入框
        Row(
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
        ),
      ],
    );
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

  /// 构建底部
  Widget _buildFooter() {
    return Text(
      '登录即表示同意相关条款',
      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
    );
  }
}
