import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/pages/activity/activity_controller.dart';
import 'package:journal_windows/services/user_service.dart';

/// 创建/编辑账本页面 - 支持弹窗和全屏两种模式
class ActivityPage extends StatelessWidget {
  final bool isDialog;
  final bool isReadOnly;

  const ActivityPage({
    super.key,
    this.isDialog = false,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final activity = Get.arguments as Activity?;
    final controller = Get.put(ActivityController(activity));

    // 判断是否为创建者
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity != null && activity.userId == currentUserId;
    final canEdit = !isReadOnly && (activity == null || isCreator);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameInput(controller, canEdit),
          const SizedBox(height: 24),
          _buildBudgetInput(controller, canEdit),
          const SizedBox(height: 24),
          _buildBudgetTypeSelector(controller, canEdit),
          const SizedBox(height: 24),
          _buildDescriptionInput(controller, canEdit),
          const SizedBox(height: 32),
          if (activity == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.create(),
                child: const Text('创建账本'),
              ),
            )
          else if (canEdit) ...[
            const Divider(height: 48),
            _buildDangerZone(controller),
          ] else ...[
            const SizedBox(height: 16),
            _buildReadOnlyIndicator(),
          ],
        ],
      ),
    );

    if (isDialog) {
      return Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        activity == null ? '创建账本' : (canEdit ? '编辑账本' : '账本详情'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (canEdit && activity != null)
                    TextButton(
                      onPressed: () async {
                        await controller.save();
                      },
                      child: const Text('保存', style: TextStyle(color: Colors.white)),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 24),
              // 内容区域
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNameInput(controller, canEdit, isDialog: true),
                      const SizedBox(height: 24),
                      _buildBudgetInput(controller, canEdit, isDialog: true),
                      const SizedBox(height: 24),
                      _buildBudgetTypeSelector(controller, canEdit, isDialog: true),
                      const SizedBox(height: 24),
                      _buildDescriptionInput(controller, canEdit, isDialog: true),
                      const SizedBox(height: 32),
                      if (activity == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => controller.create(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2D3E50),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('创建账本', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        )
                      else if (canEdit) ...[
                        const Divider(height: 48, color: Colors.white24),
                        _buildDangerZone(controller, isDialog: true),
                      ] else ...[
                        const SizedBox(height: 16),
                        _buildReadOnlyIndicator(isDialog: true),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 全屏模式
    return Scaffold(
      appBar: AppBar(
        title: Text(activity == null ? '创建账本' : (canEdit ? '编辑账本' : '账本详情')),
        actions: [
          if (canEdit && activity != null)
            TextButton(
              onPressed: () async {
                await controller.save();
              },
              child: const Text('保存'),
            ),
        ],
      ),
      body: content,
    );
  }

  /// 构建名称输入
  Widget _buildNameInput(ActivityController controller, bool canEdit, {bool isDialog = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '账本名称',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDialog ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.nameController,
          enabled: canEdit,
          style: TextStyle(color: isDialog ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: '请输入账本名称',
            hintStyle: TextStyle(color: isDialog ? Colors.white54 : Colors.grey[400]),
            filled: isDialog,
            fillColor: isDialog ? Colors.white.withValues(alpha: 0.1) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDialog ? BorderSide.none : const BorderSide(),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDialog ? BorderSide.none : const BorderSide(color: Colors.grey),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建预算输入
  Widget _buildBudgetInput(ActivityController controller, bool canEdit, {bool isDialog = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预算金额（可选）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDialog ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.budgetController,
          enabled: canEdit,
          style: TextStyle(color: isDialog ? Colors.white : Colors.black87),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '¥ ',
            prefixStyle: TextStyle(color: isDialog ? Colors.white70 : Colors.grey[700]),
            hintText: '设置预算可以帮助控制支出',
            hintStyle: TextStyle(color: isDialog ? Colors.white54 : Colors.grey[400]),
            filled: isDialog,
            fillColor: isDialog ? Colors.white.withValues(alpha: 0.1) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDialog ? BorderSide.none : const BorderSide(),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDialog ? BorderSide.none : const BorderSide(color: Colors.grey),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建预算类型选择器
  Widget _buildBudgetTypeSelector(ActivityController controller, bool canEdit, {bool isDialog = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预算周期',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDialog ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
          spacing: 12,
          children: [
            _buildTypeChip('月预算', 'monthly', controller, canEdit, isDialog),
            _buildTypeChip('周预算', 'weekly', controller, canEdit, isDialog),
            _buildTypeChip('日预算', 'daily', controller, canEdit, isDialog),
          ],
        )),
      ],
    );
  }

  Widget _buildTypeChip(String label, String value, ActivityController controller, bool canEdit, bool isDialog) {
    final isSelected = controller.budgetType.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: canEdit ? (_) => controller.setBudgetType(value) : null,
      selectedColor: isDialog ? Colors.white : Theme.of(Get.context!).primaryColor,
      backgroundColor: isDialog ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected
            ? (isDialog ? const Color(0xFF2D3E50) : Colors.white)
            : (isDialog ? Colors.white70 : Colors.grey[700]),
      ),
    );
  }

  /// 构建描述输入
  Widget _buildDescriptionInput(ActivityController controller, bool canEdit, {bool isDialog = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '账本描述（可选）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDialog ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.descriptionController,
          enabled: canEdit,
          maxLines: 3,
          style: TextStyle(color: isDialog ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: '添加账本描述...',
            hintStyle: TextStyle(color: isDialog ? Colors.white54 : Colors.grey[400]),
            filled: isDialog,
            fillColor: isDialog ? Colors.white.withValues(alpha: 0.1) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDialog ? BorderSide.none : const BorderSide(),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDialog ? BorderSide.none : const BorderSide(color: Colors.grey),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建只读提示
  Widget _buildReadOnlyIndicator({bool isDialog = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDialog ? Colors.white.withValues(alpha: 0.1) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: isDialog ? null : Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: isDialog ? Colors.white70 : Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '您是该账本的成员，只有创建者可以编辑账本信息',
              style: TextStyle(
                fontSize: 13,
                color: isDialog ? Colors.white70 : Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建危险区域
  Widget _buildDangerZone(ActivityController controller, {bool isDialog = false}) {
    return Column(
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDialog ? Colors.red.withValues(alpha: 0.1) : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDialog ? Colors.red.withValues(alpha: 0.3) : Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '删除账本',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                '删除后将无法恢复，账本内的所有账单也将被删除。',
                style: TextStyle(
                  fontSize: 12,
                  color: isDialog ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _confirmDelete(controller, isDialog),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('删除账本'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 确认删除
  void _confirmDelete(ActivityController controller, bool isDialog) {
    Get.dialog(
      AlertDialog(
        backgroundColor: isDialog ? const Color(0xFF2D3E50) : null,
        title: Text('确认删除', style: TextStyle(color: isDialog ? Colors.white : null)),
        content: Text(
          '确定要删除这个账本吗？删除后无法恢复。',
          style: TextStyle(color: isDialog ? Colors.white70 : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消', style: TextStyle(color: isDialog ? Colors.white70 : null)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.delete();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// 显示编辑账本弹窗
void showActivityDialog(Activity? activity, {bool isReadOnly = false}) {
  Get.dialog(
    ActivityPage(
      isDialog: true,
      isReadOnly: isReadOnly,
    ),
    arguments: activity,
  );
}