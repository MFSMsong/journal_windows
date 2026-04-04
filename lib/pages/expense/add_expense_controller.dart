import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/pages/expense/expense_list_controller.dart';
import 'package:journal_windows/routers.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 添加账单控制器
class AddExpenseController extends GetxController {
  final Activity? activity;

  AddExpenseController(this.activity);

  final ExpenseService _expenseService = ExpenseService.to;
  final ActivityService _activityService = ActivityService.to;

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final originalPriceController = TextEditingController();

  final isExpense = true.obs;
  final selectedCategory = ''.obs;
  final selectedDate = DateTime.now().obs;
  final isAmountValid = true.obs;  // 金额验证状态
  final isNoteValid = true.obs;    // 备注验证状态
  final isOriginalPriceValid = true.obs;  // 原价验证状态

  final categories = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initCategories();
  }

  @override
  void onClose() {
    amountController.dispose();
    noteController.dispose();
    originalPriceController.dispose();
    super.onClose();
  }

  /// 初始化分类
  void _initCategories() {
    if (isExpense.value) {
      categories.value = [
        '餐饮', '交通', '购物', '娱乐', '医疗',
        '教育', '住房', '通讯', '水电', '其他'
      ];
    } else {
      categories.value = [
        '工资', '奖金', '投资', '兼职', '红包', '其他'
      ];
    }
    selectedCategory.value = categories.first;
  }

  /// 设置支出/收入类型
  void setIsExpense(bool value) {
    isExpense.value = value;
    _initCategories();
  }

  /// 选择分类
  void selectCategory(String category) {
    selectedCategory.value = category;
  }

  /// 验证金额输入
  bool validateAmount() {
    final amountText = amountController.text.trim();
    if (amountText.isEmpty) {
      isAmountValid.value = false;
      return false;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      isAmountValid.value = false;
      return false;
    }

    isAmountValid.value = true;
    return true;
  }

  /// 验证备注输入（不超过50个汉字）
  bool validateNote() {
    final noteText = noteController.text;
    // 计算字符数（汉字算1个，其他字符也算1个）
    if (noteText.length > 50) {
      isNoteValid.value = false;
      return false;
    }
    isNoteValid.value = true;
    return true;
  }

  /// 验证原价输入
  bool validateOriginalPrice() {
    final originalPriceText = originalPriceController.text.trim();
    // 原价是可选的，如果为空则验证通过
    if (originalPriceText.isEmpty) {
      isOriginalPriceValid.value = true;
      return true;
    }

    final originalPrice = double.tryParse(originalPriceText);
    if (originalPrice == null || originalPrice <= 0) {
      isOriginalPriceValid.value = false;
      return false;
    }

    isOriginalPriceValid.value = true;
    return true;
  }

  /// 保存账单，返回是否成功
  Future<bool> save() async {
    // 验证金额
    if (!validateAmount()) {
      return false;
    }

    // 验证备注
    if (!validateNote()) {
      return false;
    }

    // 验证原价
    if (!validateOriginalPrice()) {
      return false;
    }

    if (selectedCategory.value.isEmpty) {
      ToastUtil.showInfo('请选择分类');
      return false;
    }

    final amountText = amountController.text.trim();
    final amount = double.parse(amountText);

    // 日期格式化器，后端期望格式: yyyy-MM-dd HH:mm:ss
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 构建账单对象
    final expense = Expense(
      expenseId: '',
      type: selectedCategory.value,
      price: amount,
      originalPrice: originalPriceController.text.isNotEmpty
          ? double.tryParse(originalPriceController.text)
          : null,
      label: noteController.text.trim(),
      userId: '',
      activityId: activity?.activityId ?? '',
      positive: isExpense.value ? 0 : 1,
      expenseTime: dateFormat.format(selectedDate.value),
      createTime: dateFormat.format(DateTime.now()),
    );

    // 保存
    Expense? result;
    if (activity != null) {
      result = await _expenseService.createExpense(expense);
    } else {
      result = await _expenseService.createExpenseCurrent(expense);
    }

    if (result != null) {
      ToastUtil.showSuccess('保存成功');
      // 刷新账本信息
      await _activityService.getCurrentActivity();
      // 刷新账单列表
      final expenseListController = Get.find<ExpenseListController>();
      await expenseListController.loadExpenses(refresh: true);
      return true;
    }

    return false;
  }
}