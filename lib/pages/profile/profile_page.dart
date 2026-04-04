import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/profile/profile_controller.dart';
import 'package:journal_windows/pages/profile/edit_profile_page.dart';

/// 个人信息页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '个人信息',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                // 刷新按钮
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: '刷新',
                  onPressed: () => controller.refreshUserProfile(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildProfileCard(context, controller),
            const SizedBox(height: 24),
            _buildSettingsCard(context),
            const SizedBox(height: 24),
            _buildDangerZone(controller),
          ],
        ),
      ),
    );
  }

  /// 构建个人资料卡片
  Widget _buildProfileCard(BuildContext context, ProfileController controller) {
    return Obx(() {
      final user = controller.userService.currentUser.value;
      if (user == null) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('暂无用户信息')),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 头像和昵称
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? NetworkImage(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user.vip) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VIP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${user.userId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditProfileDialog(),
                    tooltip: '编辑资料',
                  ),
                ],
              ),
              const Divider(height: 32),
              // 详细信息
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.phone_outlined,
                      '手机号',
                      user.telephone ?? '未设置',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today_outlined,
                      '注册时间',
                      user.createTime.isNotEmpty 
                          ? user.createTime.substring(0, 10)
                          : '-',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  /// 构建信息项
  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建设置卡片
  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildSettingItem(
            Icons.edit_outlined,
            '编辑资料',
            '修改昵称、头像等信息',
            () => _showEditProfileDialog(),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            Icons.notifications_outlined,
            '通知设置',
            '管理应用通知',
            () => Get.snackbar('提示', '功能开发中'),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            Icons.security_outlined,
            '隐私设置',
            '管理隐私相关设置',
            () => Get.snackbar('提示', '功能开发中'),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            Icons.help_outline,
            '帮助与反馈',
            '获取帮助或提交反馈',
            () => Get.snackbar('提示', '功能开发中'),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            Icons.info_outline,
            '关于',
            '版本 1.0.0',
            () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  /// 构建设置项
  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// 构建危险区域
  Widget _buildDangerZone(ProfileController controller) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '危险区域',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '删除账户后，所有数据将被永久删除，无法恢复。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _showDeleteDialog(controller),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('删除账户'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于好享记账'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 1.0.0'),
            SizedBox(height: 8),
            Text('好享记账是一款多人协作记账应用，支持：'),
            SizedBox(height: 4),
            Text('• 多人协作记账'),
            Text('• AI智能记账'),
            Text('• 数据统计分析'),
            Text('• 跨平台同步'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示编辑资料对话框
  void _showEditProfileDialog() {
    Get.dialog(
      const EditProfileDialog(),
      barrierDismissible: true,
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(ProfileController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除账户'),
        content: const Text('删除账户后，所有数据将被永久删除，无法恢复。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteAccount();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
