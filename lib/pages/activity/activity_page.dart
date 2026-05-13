import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/activity_member.dart';
import 'package:journal_windows/pages/activity/activity_controller.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/widgets/cos_image.dart';

/// 创建/编辑账本页面 - 支持弹窗和全屏两种模式
class ActivityPage extends StatefulWidget {
  final bool isDialog;
  final bool isReadOnly;

  const ActivityPage({
    super.key,
    this.isDialog = false,
    this.isReadOnly = false,
  });

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  Activity? activity;
  ActivityController? controller;
  List<ActivityMember> members = [];
  bool isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      activity = Get.arguments as Activity?;
      controller = Get.put(ActivityController(activity));
      if (activity != null) {
        _loadMembers();
      } else {
        isLoadingMembers = false;
      }
      setState(() {});
    });
  }

  Future<void> _loadMembers() async {
    if (activity == null) return;
    setState(() => isLoadingMembers = true);
    members = await ActivityService.to.getActivityMembers(activity!.activityId);
    setState(() => isLoadingMembers = false);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity != null && activity!.userId == currentUserId;
    final canEdit = !widget.isReadOnly && (activity == null || isCreator);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameInput(controller!, canEdit),
          const SizedBox(height: 24),
          _buildBudgetInput(controller!, canEdit),
          const SizedBox(height: 24),
          _buildDescriptionInput(controller!, canEdit),
          if (activity != null) ...[
            const SizedBox(height: 24),
            _buildStatisticsSection(),
          ],
          if (activity != null) ...[
            const SizedBox(height: 24),
            _buildMembersSection(),
          ],
          const SizedBox(height: 32),
          if (activity == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller!.create(),
                child: const Text('创建账本'),
              ),
            )
          else if (canEdit) ...[
            const Divider(height: 48),
            _buildDangerZone(controller!),
          ] else ...[
            const SizedBox(height: 16),
            _buildReadOnlyIndicator(),
          ],
        ],
      ),
    );

    if (widget.isDialog) {
      return Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCreator, canEdit),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNameInput(controller!, canEdit, isDialog: true),
                      const SizedBox(height: 24),
                      _buildBudgetInput(controller!, canEdit, isDialog: true),
                      const SizedBox(height: 24),
                      _buildDescriptionInput(controller!, canEdit, isDialog: true),
                      if (activity != null) ...[
                        const SizedBox(height: 24),
                        _buildStatisticsSection(isDialog: true),
                      ],
                      if (activity != null) ...[
                        const SizedBox(height: 24),
                        _buildMembersSection(isDialog: true),
                      ],
                      const SizedBox(height: 32),
                      if (activity == null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => controller!.create(),
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
                        _buildDangerZone(controller!, isDialog: true),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(activity == null ? '创建账本' : (canEdit ? '编辑账本' : '账本详情')),
        actions: [
          if (canEdit && activity != null)
            TextButton(
              onPressed: () async {
                await controller!.save();
              },
              child: const Text('保存'),
            ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildHeader(bool isCreator, bool canEdit) {
    return Row(
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
              await controller!.save();
            },
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          )
        else
          const SizedBox(width: 40),
      ],
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

  /// 构建统计信息区域
  Widget _buildStatisticsSection({bool isDialog = false}) {
    final totalExpense = activity?.totalExpense ?? 0;
    final totalIncome = activity?.totalIncome ?? 0;
    final balance = totalIncome - totalExpense;
    final budget = activity?.budget ?? 0;
    final hasBudget = budget > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '账本统计',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDialog ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDialog ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '总支出',
                      totalExpense,
                      Colors.red,
                      isDialog,
                      isExpense: true,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDialog ? Colors.white24 : Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '总收入',
                      totalIncome,
                      Colors.green,
                      isDialog,
                      isExpense: false,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: isDialog ? Colors.white24 : Colors.grey[300],
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '结余',
                      balance.abs(),
                      balance >= 0 ? Colors.blue : Colors.orange,
                      isDialog,
                      isExpense: balance < 0,
                      prefix: balance < 0 ? '-' : '',
                    ),
                  ),
                ],
              ),
              if (hasBudget) ...[
                const SizedBox(height: 16),
                _buildBudgetProgress(totalExpense, budget, isDialog),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    String label,
    double value,
    Color color,
    bool isDialog, {
    bool isExpense = false,
    String prefix = '',
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDialog ? Colors.white54 : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$prefix¥${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDialog ? Colors.white : color,
          ),
        ),
      ],
    );
  }

  /// 构建预算进度条
  Widget _buildBudgetProgress(double totalExpense, double budget, bool isDialog) {
    final usagePercent = budget > 0 ? (totalExpense / budget * 100).clamp(0, 100) : 0.0;
    final remaining = budget - totalExpense;
    final isOverBudget = remaining < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '预算使用',
              style: TextStyle(
                fontSize: 12,
                color: isDialog ? Colors.white54 : Colors.grey[500],
              ),
            ),
            Text(
              isOverBudget 
                  ? '已超支 ¥${remaining.abs().toStringAsFixed(2)}'
                  : '剩余 ¥${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: isOverBudget ? Colors.red : (isDialog ? Colors.white70 : Colors.grey[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: usagePercent / 100,
            backgroundColor: isDialog ? Colors.white24 : Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isOverBudget ? Colors.red : (usagePercent > 80 ? Colors.orange : Colors.green),
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '预算 ¥${budget.toStringAsFixed(2)} · 已用 ${usagePercent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: isDialog ? Colors.white38 : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  /// 构建成员区域
  Widget _buildMembersSection({bool isDialog = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '账本成员',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDialog ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _showSetNicknameDialog,
              icon: Icon(Icons.edit, size: 16, color: isDialog ? Colors.white70 : Colors.grey[600]),
              label: Text(
                '设置昵称',
                style: TextStyle(color: isDialog ? Colors.white70 : Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        isLoadingMembers
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDialog ? Colors.white : null,
                    ),
                  ),
                ),
              )
            : members.isEmpty
                ? _buildEmptyMembers(isDialog)
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDialog ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: members.map((member) => _buildMemberItem(member, isDialog)).toList(),
                    ),
                  ),
      ],
    );
  }

  Widget _buildEmptyMembers(bool isDialog) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDialog ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.group_off, size: 32, color: isDialog ? Colors.white30 : Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              '暂无成员',
              style: TextStyle(
                fontSize: 13,
                color: isDialog ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(ActivityMember member, bool isDialog) {
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCurrentUser = member.userId == currentUserId;
    final isCreator = activity?.userId == currentUserId;
    final hasCustomNickname = member.activityNickname?.isNotEmpty == true;
    final canEditNickname = isCreator || isCurrentUser;
    final canKick = isCreator && !member.isOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _buildAvatar(member),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        hasCustomNickname ? member.activityNickname! : member.nickname,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDialog ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '创建者',
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ),
                    ],
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '我',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasCustomNickname ? '原名：${member.nickname}' : member.nickname,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDialog ? Colors.white.withValues(alpha: 0.6) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          if (canEditNickname || canKick) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEditNickname)
                  IconButton(
                    onPressed: () => _showSetNicknameDialog(targetMember: member),
                    icon: Icon(
                      Icons.edit,
                      size: 18,
                      color: isDialog ? Colors.white54 : Colors.grey[500],
                    ),
                    tooltip: '修改昵称',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                if (canKick)
                  IconButton(
                    onPressed: () => _showKickConfirm(member),
                    icon: Icon(
                      Icons.person_remove,
                      size: 18,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    tooltip: '移除成员',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ActivityMember member) {
    final hasAvatar = member.avatarUrl?.isNotEmpty == true;
    if (hasAvatar) {
      return SizedBox(
        width: 36,
        height: 36,
        child: ClipOval(
          child: CosImage(
            cosPath: member.avatarUrl!,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.primaries[member.userId.hashCode % Colors.primaries.length],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          member.nickname.isNotEmpty ? member.nickname.substring(0, 1) : '?',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSetNicknameDialog({ActivityMember? targetMember}) {
    final textController = TextEditingController();
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    
    final member = targetMember ?? members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => ActivityMember(userId: '', nickname: '', isOwner: false),
    );
    textController.text = member.activityNickname ?? '';

    final isCurrentUser = member.userId == currentUserId;
    final displayName = member.activityNickname?.isNotEmpty == true 
        ? member.activityNickname! 
        : member.nickname;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        isCurrentUser ? '设置我的昵称' : '设置 $displayName 的昵称',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                isCurrentUser 
                    ? '设置您在这个账本中的昵称，方便其他成员识别您'
                    : '为该成员设置在这个账本中的昵称',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '例如：爸爸、妈妈、老公、老婆...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                maxLength: 10,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveNickname(textController.text, userId: member.userId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2D3E50),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveNickname(String nickname, {String? userId}) async {
    if (nickname.trim().isEmpty) {
      ToastUtil.showInfo('请输入昵称');
      return;
    }

    bool success = false;
    await ActivityService.to.updateNickname(
      activity!.activityId,
      nickname.trim(),
      targetUserId: userId,
      onSuccess: (msg) {
        success = true;
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );

    if (success) {
      Get.back();
      ToastUtil.showSuccess('昵称设置成功');
      await _loadMembers();
    }
  }

  void _showKickConfirm(ActivityMember member) {
    final displayName = member.activityNickname?.isNotEmpty == true 
        ? member.activityNickname! 
        : member.nickname;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2D3E50),
        title: const Text('确认移除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要将 $displayName 移出账本吗？\n移除后该成员将无法查看此账本。',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('取消', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _kickMember(member);
            },
            child: const Text('移除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _kickMember(ActivityMember member) async {
    bool success = false;
    await ActivityService.to.kickMember(
      activity!.activityId,
      member.userId,
      onSuccess: (msg) {
        success = true;
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );

    if (success) {
      ToastUtil.showSuccess('已移除成员');
      await _loadMembers();
    }
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
