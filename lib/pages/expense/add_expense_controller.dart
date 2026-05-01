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

class AddExpenseController extends GetxController {
  final Activity? activity;
  final Expense? existingExpense;

  AddExpenseController({this.activity, this.existingExpense});

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
  final existingImagePaths = <String>[].obs;
  final isUploadingImages = false.obs;

  bool get isEditMode => existingExpense != null;

  @override
  void onInit() {
    super.onInit();
    _initCategories();
    if (isEditMode) {
      _loadExistingExpense();
    }
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
    if (selectedCategory.value.isEmpty) {
      selectedCategory.value = categories.first;
    }
  }

  void _loadExistingExpense() {
    final expense = existingExpense!;
    isExpense.value = expense.isExpense;
    _initCategories();
    selectedCategory.value = expense.type;
    selectedDate.value = DateTime.tryParse(expense.expenseTime) ?? DateTime.now();
    amountController.text = expense.price.toStringAsFixed(2);
    noteController.text = expense.label;
    if (expense.originalPrice != null) {
      originalPriceController.text = expense.originalPrice!.toStringAsFixed(2);
    }
    if (expense.fileList != null && expense.fileList!.isNotEmpty) {
      existingImagePaths.value = List.from(expense.fileList!);
    }
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
    final totalImages = existingImagePaths.length + selectedImagePaths.length;
    if (totalImages >= 3) {
      ToastUtil.showInfo('最多上传3张图片');
      return;
    }
    final imagePath = await ImageCropUtil.pickAndCropImage(Get.context!);
    if (imagePath != null) {
      selectedImagePaths.add(imagePath);
    }
  }

  void removeNewImage(int index) {
    if (index < selectedImagePaths.length) {
      selectedImagePaths.removeAt(index);
    }
  }

  void removeExistingImage(int index) {
    if (index < existingImagePaths.length) {
      existingImagePaths.removeAt(index);
    }
  }

  int get totalImageCount => existingImagePaths.length + selectedImagePaths.length;

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

    List<String> fileListData = [...existingImagePaths, ...uploadedCosPaths];
    if (fileListData.isEmpty) {
      fileListData = [];
    }

    final expense = Expense(
      expenseId: isEditMode ? existingExpense!.expenseId : '',
      type: selectedCategory.value,
      price: amount,
      originalPrice: originalPriceController.text.isNotEmpty
          ? double.tryParse(originalPriceController.text)
          : null,
      label: noteController.text.trim(),
      userId: isEditMode ? existingExpense!.userId : '',
      activityId: activity?.activityId ?? (isEditMode ? existingExpense!.activityId : ''),
      positive: isExpense.value ? 0 : 1,
      expenseTime: dateFormat.format(selectedDate.value),
      createTime: isEditMode ? existingExpense!.createTime : dateFormat.format(DateTime.now()),
      fileList: fileListData.isEmpty ? null : fileListData,
    );

    bool success;
    if (isEditMode) {
      success = await _expenseService.updateExpense(expense);
    } else if (activity != null) {
      success = await _expenseService.createExpense(expense) != null;
    } else {
      success = await _expenseService.createExpenseCurrent(expense) != null;
    }

    if (success) {
      final expenseListController = Get.find<ExpenseListController>();
      await expenseListController.loadActivities();
      return true;
    }

    return false;
  }
}
