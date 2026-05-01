import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 提示工具类
class ToastUtil {
  /// 显示成功提示
  static void showSuccess(String message) {
    _showSnackBar('成功', message, Colors.green);
  }

  /// 显示错误提示
  static void showError(String message) {
    _showSnackBar('错误', message, Colors.red);
  }

  /// 显示提示信息
  static void showInfo(String message) {
    _showSnackBar('提示', message, Colors.blue);
  }

  /// 显示 SnackBar
  static void _showSnackBar(String title, String message, Color backgroundColor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(
        title,
        message,
        duration: const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        snackStyle: SnackStyle.FLOATING,
        overlayBlur: 0,
        overlayColor: Colors.transparent,
      );
    });
  }

  /// 关闭当前页面
  static void closePage({dynamic result}) {
    // 先关闭所有 Snackbar，避免 Get.back 关闭 Snackbar 而不是页面
    Get.closeAllSnackbars();
    // 使用 Navigator 确保关闭的是页面/Dialog 而不是 Snackbar
    if (Get.context != null) {
      Navigator.of(Get.context!).pop(result);
    } else {
      Get.back(result: result);
    }
  }

  /// 显示对话框
  static void showDialog({
    required String title,
    required String content,
    String cancelText = '取消',
    String confirmText = '确定',
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    bool isDanger = false,
  }) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => closePage(),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: onConfirm,
            style: isDanger 
                ? TextButton.styleFrom(foregroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}