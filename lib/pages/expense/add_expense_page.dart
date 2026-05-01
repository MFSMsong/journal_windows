import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/pages/expense/add_expense_controller.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/utils/ui_util.dart';
import 'package:journal_windows/widgets/cos_image.dart';

class AddExpensePage extends StatelessWidget {
  final Activity? activity;
  final Expense? existingExpense;
  final VoidCallback? onClose;

  const AddExpensePage({
    super.key,
    this.activity,
    this.existingExpense,
    this.onClose,
  });

  bool get isEditMode => existingExpense != null;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      AddExpenseController(activity: activity, existingExpense: existingExpense),
      tag: existingExpense?.expenseId ?? DateTime.now().toString(),
    );

    return Container(
      width: 480,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(controller),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSelector(controller),
                  const SizedBox(height: 24),
                  _buildAmountInput(controller),
                  const SizedBox(height: 24),
                  _buildCategorySelector(controller),
                  const SizedBox(height: 24),
                  _buildNoteInput(controller),
                  const SizedBox(height: 24),
                  _buildDatePicker(controller),
                  const SizedBox(height: 24),
                  _buildOriginalPriceInput(controller),
                  const SizedBox(height: 24),
                  _buildImagePicker(controller),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildSaveButton(controller),
        ],
      ),
    );
  }

  Widget _buildHeader(AddExpenseController controller) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose ?? () => Get.back(),
          icon: const Icon(Icons.close, color: Colors.white70, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Center(
            child: Text(
              isEditMode ? '编辑账单' : '记一笔',
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

  Widget _buildTypeSelector(AddExpenseController controller) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              '支出',
              controller.isExpense.value,
              () => controller.setIsExpense(true),
              Colors.red,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              '收入',
              !controller.isExpense.value,
              () => controller.setIsExpense(false),
              Colors.green,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildTypeButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
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

  Widget _buildAmountInput(AddExpenseController controller) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '金额',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (!controller.isAmountValid.value) ...[
              const SizedBox(width: 8),
              const Text(
                '请输入有效金额',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: !controller.isAmountValid.value
                ? Border.all(color: Colors.redAccent, width: 2)
                : null,
          ),
          child: TextField(
            controller: controller.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) {
              if (!controller.isAmountValid.value) {
                controller.isAmountValid.value = true;
              }
            },
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: !controller.isAmountValid.value ? Colors.redAccent : Colors.white,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              prefixText: '¥ ',
              prefixStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: !controller.isAmountValid.value ? Colors.redAccent : Colors.white,
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
        ),
      ],
    ));
  }

  Widget _buildCategorySelector(AddExpenseController controller) {
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
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.categories.map((category) {
            final isSelected = controller.selectedCategory.value == category;
            final icon = UiUtil.getExpenseIcon(category);
            return GestureDetector(
              onTap: () => controller.selectCategory(category),
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(Get.context!).primaryColor.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 28),
                    ),
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
        )),
      ],
    );
  }

  Widget _buildNoteInput(AddExpenseController controller) {
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
          controller: controller.noteController,
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

  Widget _buildDatePicker(AddExpenseController controller) {
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
        Obx(() => InkWell(
          onTap: () => _selectDate(controller),
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
                  controller.selectedDate.value.toString().split(' ').first,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.white70),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildOriginalPriceInput(AddExpenseController controller) {
    return Obx(() {
      if (!controller.isExpense.value) return const SizedBox();

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
            controller: controller.originalPriceController,
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
    });
  }

  Widget _buildSaveButton(AddExpenseController controller) {
    return Obx(() => SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.isUploadingImages.value ? null : () => _save(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D3E50),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: controller.isUploadingImages.value
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('上传图片中...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              )
            : Text(
                isEditMode ? '保存修改' : '保存',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ));
  }

  Widget _buildImagePicker(AddExpenseController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '附件图片',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '最多3张（可选）',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...controller.existingImagePaths.asMap().entries.map((entry) {
              final index = entry.key;
              final cosPath = entry.value;
              return _buildExistingImageItem(cosPath, index, controller);
            }),
            ...controller.selectedImagePaths.asMap().entries.map((entry) {
              final index = entry.key;
              final imagePath = entry.value;
              return _buildNewImageItem(imagePath, index, controller);
            }),
            if (controller.totalImageCount < 3)
              _buildAddImageButton(controller),
          ],
        )),
      ],
    );
  }

  Widget _buildExistingImageItem(String cosPath, int index, AddExpenseController controller) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CosImage(
              cosPath: cosPath,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: GestureDetector(
            onTap: () => controller.removeExistingImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewImageItem(String imagePath, int index, AddExpenseController controller) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(File(imagePath)),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: GestureDetector(
            onTap: () => controller.removeNewImage(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(AddExpenseController controller) {
    return GestureDetector(
      onTap: () => controller.pickImage(),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: Colors.white.withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              '添加图片',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(AddExpenseController controller) async {
    final date = await showDatePicker(
      context: Get.context!,
      initialDate: controller.selectedDate.value,
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
      controller.selectedDate.value = date;
    }
  }

  Future<void> _save(AddExpenseController controller) async {
    final success = await controller.save();
    if (success) {
      if (isEditMode) {
        Get.closeAllSnackbars();
        Get.back();
        Get.back();
        ToastUtil.showSuccess('修改成功');
      } else {
        ToastUtil.closePage();
        ToastUtil.showSuccess('保存成功');
      }
    }
  }
}
