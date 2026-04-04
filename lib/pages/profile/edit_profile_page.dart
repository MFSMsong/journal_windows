import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/profile/edit_profile_controller.dart';

/// 编辑个人信息对话框
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late EditProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(EditProfileController());
  }

  @override
  void dispose() {
    Get.delete<EditProfileController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2D3E50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Text(
                  '编辑资料',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 头像选择器
            _buildAvatarSelector(context, controller),
            const SizedBox(height: 24),
            // 昵称输入
            _buildNicknameInput(controller),
            const SizedBox(height: 16),
            // 个人简介输入
            _buildOpeningStatementInput(controller),
            const SizedBox(height: 24),
            // 按钮区域
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () => controller.save(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D3E50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2D3E50),
                            ),
                          )
                        : const Text(
                            '保存',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建头像选择器
  Widget _buildAvatarSelector(BuildContext context, EditProfileController controller) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Obx(() => CircleAvatar(
                radius: 50,
                backgroundImage: controller.avatarUrl.value.isNotEmpty
                    ? NetworkImage(controller.avatarUrl.value)
                    : null,
                backgroundColor: Colors.white24,
                child: controller.avatarUrl.value.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.white70)
                    : null,
              )),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF2D3E50), size: 20),
                    onPressed: () => controller.pickAndUploadAvatar(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '点击更换头像',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建昵称输入
  Widget _buildNicknameInput(EditProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '昵称',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.nicknameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '请输入昵称',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  /// 构建个人简介输入
  Widget _buildOpeningStatementInput(EditProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '个人简介',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.openingStatementController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '介绍一下自己吧',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.edit_outlined, color: Colors.white.withValues(alpha: 0.6)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// 编辑个人信息页面（保留兼容旧代码）
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EditProfileDialog();
  }
}

/// 显示编辑个人资料弹窗
void showEditProfileDialog() {
  Get.dialog(
    const EditProfileDialog(),
    barrierDismissible: true,
  );
}