import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/pages/expense/expense_list_controller.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/utils/ui_util.dart';
import 'package:journal_windows/widgets/cos_image.dart';
import 'package:journal_windows/pages/expense/add_expense_page.dart';

class ExpenseDetailPage extends StatelessWidget {
  final Expense expense;
  final Activity activity;

  const ExpenseDetailPage({
    super.key,
    required this.expense,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity.userId == currentUserId;
    final isExpenseOwner = expense.userId == currentUserId;
    final canEdit = isCreator || isExpenseOwner;

    return Dialog(
      backgroundColor: const Color(0xFF2D3E50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: _buildViewContent(),
              ),
            ),
            const SizedBox(height: 24),
            if (canEdit) _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => ToastUtil.closePage(),
          icon: const Icon(Icons.close, color: Colors.white70, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Center(
            child: Text(
              '账单详情',
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
    );
  }

  Widget _buildViewContent() {
    final isExpenseType = expense.isExpense;
    final color = isExpenseType ? Colors.red : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    UiUtil.getExpenseIcon(expense.type),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.type,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExpenseType ? '支出' : '收入',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpenseType ? "-" : "+"}¥${expense.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildViewItem(Icons.access_time, '时间', _formatTime(expense.expenseTime)),
        const SizedBox(height: 16),
        _buildViewItem(Icons.person_outline, '记录者', expense.userNickname ?? '未知用户'),
        const SizedBox(height: 16),
        _buildViewItem(Icons.label_outline, '备注', expense.label.isEmpty ? '无' : expense.label),
        if (expense.hasDiscount) ...[
          const SizedBox(height: 16),
          _buildViewItem(Icons.local_offer, '折扣', '原价 ¥${expense.originalPrice?.toStringAsFixed(2)}，省 ¥${expense.savedAmount.toStringAsFixed(2)}'),
        ],
        if (expense.fileList != null && expense.fileList!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBillImages(expense.fileList!),
        ],
      ],
    );
  }

  Widget _buildViewItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBillImages(List<String> fileList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 20, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Text(
              '附件图片',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fileList.map((cosPath) => GestureDetector(
            onTap: () => _showImagePreview(cosPath),
            child: CosImage(
              cosPath: cosPath,
              width: 100,
              height: 100,
              borderRadius: BorderRadius.circular(8),
            ),
          )).toList(),
        ),
      ],
    );
  }

  void _showImagePreview(String cosPath) {
    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: CosImage(
                cosPath: cosPath,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _openEditPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2D3E50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('编辑'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _deleteExpense,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('删除'),
          ),
        ),
      ],
    );
  }

  void _openEditPage() {
    showDialog(
      context: Get.context!,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AddExpensePage(
          activity: activity,
          existingExpense: expense,
          onClose: () => Get.back(),
        ),
      ),
    );
  }

  Future<void> _deleteExpense() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2D3E50),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: const Text('确定要删除这条账单吗？', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ExpenseService.to.deleteExpense(expense.expenseId, activity.activityId);
      if (success) {
        ToastUtil.showSuccess('删除成功');
        Get.back();
        final expenseListController = Get.find<ExpenseListController>();
        await expenseListController.loadActivities();
      }
    }
  }

  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

      String dateStr;
      if (date == today) {
        dateStr = '今天';
      } else if (date == today.subtract(const Duration(days: 1))) {
        dateStr = '昨天';
      } else {
        dateStr = '${dateTime.month}月${dateTime.day}日';
      }

      final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$dateStr $timeStr';
    } catch (e) {
      return time;
    }
  }
}
