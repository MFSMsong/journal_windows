import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/tencent_service.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/pages/expense/expense_list_controller.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/utils/image_crop_util.dart';

/// 添加账单控制器
class AddExpenseController extends GetxController {
  final Activity? activity;

  AddExpenseController(this.activity);

  final ExpenseService _expenseService = ExpenseService.to;

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final originalPriceController = TextEditingController();

  final isExpense = true.obs;
  final selectedCategory = ''.obs;
  final selectedDate = DateTime.now().obs;
  final isAmountValid = true.obs;
  final isNoteValid = true.obs;
  final isOriginalPriceValid = true.obs;

  final categories = <String>[].obs;

  final selectedImagePaths = <String>[].obs;
  final uploadedCosPaths = <String>[].obs;
  final isUploadingImages = false.obs;

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

  void setIsExpense(bool value) {
    isExpense.value = value;
    _initCategories();
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
  }

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

  bool validateNote() {
    final noteText = noteController.text;
    if (noteText.length > 50) {
      isNoteValid.value = false;
      return false;
    }
    isNoteValid.value = true;
    return true;
  }

  bool validateOriginalPrice() {
    final originalPriceText = originalPriceController.text.trim();
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

  Future<void> pickImage() async {
    if (selectedImagePaths.length >= 3) {
      ToastUtil.showInfo('最多上传3张图片');
      return;
    }
    final imagePath = await ImageCropUtil.pickAndCropImage(Get.context!);
    if (imagePath != null) {
      selectedImagePaths.add(imagePath);
    }
  }

  void removeImage(int index) {
    if (index < selectedImagePaths.length) {
      selectedImagePaths.removeAt(index);
    }
  }

  Future<bool> save() async {
    if (!validateAmount()) return false;
    if (!validateNote()) return false;
    if (!validateOriginalPrice()) return false;

    if (selectedCategory.value.isEmpty) {
      ToastUtil.showInfo('请选择分类');
      return false;
    }

    if (selectedImagePaths.isNotEmpty) {
      isUploadingImages.value = true;
      final userId = UserService.to.currentUser.value?.userId ?? '';
      for (final imagePath in selectedImagePaths) {
        final cosPath = await TencentService.to.uploadBillImage(imagePath, userId);
        if (cosPath != null) {
          uploadedCosPaths.add(cosPath);
        } else {
          isUploadingImages.value = false;
          ToastUtil.showError('图片上传失败，请重试');
          return false;
        }
      }
      isUploadingImages.value = false;
    }

    final amountText = amountController.text.trim();
    final amount = double.parse(amountText);

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    List<String>? fileListData;
    if (uploadedCosPaths.isNotEmpty) {
      fileListData = uploadedCosPaths.toList();
    }

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
      fileList: fileListData,
    );

    Expense? result;
    if (activity != null) {
      result = await _expenseService.createExpense(expense);
    } else {
      result = await _expenseService.createExpenseCurrent(expense);
    }

    if (result != null) {
      ToastUtil.showSuccess('保存成功');
      final expenseListController = Get.find<ExpenseListController>();
      await expenseListController.loadActivities();
      return true;
    }

    return false;
  }
}