import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/pages/expense/expense_list_controller.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/utils/ui_util.dart';
import 'package:intl/intl.dart';

/// 账单详情/编辑页面
class ExpenseDetailPage extends StatefulWidget {
  final Expense expense;
  final Activity activity;

  const ExpenseDetailPage({
    super.key,
    required this.expense,
    required this.activity,
  });

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  late TextEditingController _noteController;
  late TextEditingController _amountController;
  late TextEditingController _originalPriceController;

  bool _isEditing = false;
  bool _isSaving = false;

  late bool _isExpense;
  late String _selectedCategory;
  late DateTime _selectedDate;

  final currentUserId = UserService.to.currentUser.value?.userId ?? '';
  bool get isCreator => widget.activity.userId == currentUserId;
  bool get isExpenseOwner => widget.expense.userId == currentUserId;
  bool get canEdit => isCreator || isExpenseOwner;

  List<String> get expenseCategories => [
    '餐饮', '交通', '购物', '娱乐', '医疗',
    '教育', '住房', '通讯', '水电', '其他'
  ];

  List<String> get incomeCategories => [
    '工资', '奖金', '投资', '兼职', '红包', '其他'
  ];

  List<String> get categories => _isExpense ? expenseCategories : incomeCategories;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.expense.isExpense;
    _selectedCategory = widget.expense.type;
    _selectedDate = DateTime.tryParse(widget.expense.expenseTime) ?? DateTime.now();

    _noteController = TextEditingController(text: widget.expense.label);
    _amountController = TextEditingController(text: widget.expense.price.toStringAsFixed(2));
    _originalPriceController = TextEditingController(
      text: widget.expense.originalPrice?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                child: _isEditing
                    ? _buildEditContent()
                    : _buildViewContent(),
              ),
            ),
            const SizedBox(height: 24),
            _buildBottomButton(),
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
              _isEditing ? '编辑账单' : '账单详情',
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
    final expense = widget.expense;
    final isExpense = expense.isExpense;
    final color = isExpense ? Colors.red : Colors.green;

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
                      isExpense ? '支出' : '收入',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isExpense ? "-" : "+"}¥${expense.price.toStringAsFixed(2)}',
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

  Widget _buildEditContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 24),
        _buildAmountInput(),
        const SizedBox(height: 24),
        _buildCategorySelector(),
        const SizedBox(height: 24),
        _buildNoteInput(),
        const SizedBox(height: 24),
        _buildDatePicker(),
        if (_isExpense) ...[
          const SizedBox(height: 24),
          _buildOriginalPriceInput(),
        ],
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              '支出',
              _isExpense,
              () => _setType(true),
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              '收入',
              !_isExpense,
              () => _setType(false),
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  void _setType(bool isExpense) {
    setState(() {
      _isExpense = isExpense;
      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = categories.first;
      }
    });
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金额',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            prefixText: '¥ ',
            prefixStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            hintText: '0.00',
            hintStyle: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            final icon = UiUtil.getExpenseIcon(category);
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            hintText: '添加备注...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日期',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.white70),
                const SizedBox(width: 12),
                Text(
                  _selectedDate.toString().split(' ').first,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.white70),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalPriceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '原价（可选）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '用于记录折扣',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _originalPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            prefixText: '¥ ',
            prefixStyle: const TextStyle(color: Colors.white70),
            hintText: '如有折扣可填写原价',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    if (!canEdit) {
      return const SizedBox.shrink();
    }

    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => setState(() => _isEditing = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2D3E50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2D3E50),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('编辑', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showDeleteConfirm,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('删除'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2D3E50),
              surface: Color(0xFF2D3E50),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      return DateFormat('yyyy年MM月dd日 HH:mm').format(dateTime);
    } catch (e) {
      return time;
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ToastUtil.showError('请输入有效金额');
      return;
    }

    if (_selectedCategory.isEmpty) {
      ToastUtil.showInfo('请选择分类');
      return;
    }

    setState(() => _isSaving = true);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    final updatedExpense = Expense(
      expenseId: widget.expense.expenseId,
      type: _selectedCategory,
      price: amount,
      originalPrice: _originalPriceController.text.isNotEmpty
          ? double.tryParse(_originalPriceController.text)
          : null,
      label: _noteController.text.trim(),
      userId: widget.expense.userId,
      activityId: widget.expense.activityId,
      positive: _isExpense ? 0 : 1,
      expenseTime: dateFormat.format(_selectedDate),
      createTime: widget.expense.createTime,
      userNickname: widget.expense.userNickname,
      userAvatar: widget.expense.userAvatar,
    );

    await ExpenseService.to.updateExpense(
      updatedExpense,
      onSuccess: (msg) async {
        setState(() => _isSaving = false);
        await ActivityService.to.getCurrentActivity();
        final expenseListController = Get.find<ExpenseListController>();
        await expenseListController.loadExpenses(refresh: true);
        ToastUtil.closePage(result: true);
      },
      onFail: (msg) {
        setState(() => _isSaving = false);
        ToastUtil.showError(msg);
      },
    );
  }

  void _showDeleteConfirm() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2D3E50),
        title: const Text('确认删除', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除这条${widget.expense.isExpense ? '支出' : '收入'}记录吗？\n金额：¥${widget.expense.price.toStringAsFixed(2)}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => ToastUtil.closePage(),
            child: Text('取消', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              ToastUtil.closePage();
              _deleteExpense();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense() async {
    await ExpenseService.to.deleteExpense(
      widget.expense.expenseId,
      widget.expense.activityId,
      onSuccess: (msg) async {
        await ActivityService.to.getCurrentActivity();
        final expenseListController = Get.find<ExpenseListController>();
        await expenseListController.loadExpenses(refresh: true);
        ToastUtil.closePage(result: true);
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }
}
