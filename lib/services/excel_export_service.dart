import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// Excel导出服务
class ExcelExportService {
  /// 导出账单列表为Excel
  /// [expenses] 账单列表
  /// [activityName] 账本名称
  static Future<bool> exportExpenses({
    required List<Expense> expenses,
    required String activityName,
  }) async {
    if (expenses.isEmpty) {
      ToastUtil.showInfo('暂无数据可导出');
      return false;
    }

    try {
      // 选择保存位置
      final outputPath = await _pickSavePath('$activityName-账单记录');
      if (outputPath == null) {
        return false;
      }

      // 创建Excel
      final excel = Excel.createExcel();
      // 重命名默认的Sheet1为账本名称
      excel.rename('Sheet1', activityName);
      // 获取重命名后的sheet
      final sheet = excel[activityName];

      // 设置表头
      final headers = ['序号', '类型', '金额', '标签', '日期', '时间', '用户', '备注'];
      final headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.grey,
      );

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByString('${_getColumnLetter(i)}1'));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // 填充数据
      for (var i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        final row = i + 2;

        // 序号
        sheet.cell(CellIndex.indexByString('${_getColumnLetter(0)}$row'))
            .value = IntCellValue(i + 1);

        // 类型
        sheet.cell(CellIndex.indexByString('${_getColumnLetter(1)}$row'))
            .value = TextCellValue(expense.type);

        // 金额（支出显示负数，收入显示正数）
        final amount = expense.isExpense ? -expense.price : expense.price;
        final amountCell = sheet.cell(CellIndex.indexByString('${_getColumnLetter(2)}$row'));
        amountCell.value = DoubleCellValue(amount);
        amountCell.cellStyle = CellStyle(
          fontColorHex: expense.isExpense ? ExcelColor.red : ExcelColor.green,
        );

        // 标签
        sheet.cell(CellIndex.indexByString('${_getColumnLetter(3)}$row'))
            .value = TextCellValue(expense.label);

        // 日期和时间
        final dateTimeParts = expense.expenseTime.split(' ');
        final date = dateTimeParts.isNotEmpty ? dateTimeParts[0] : '';
        final time = dateTimeParts.length > 1 ? dateTimeParts[1].substring(0, 5) : '';

        sheet.cell(CellIndex.indexByString('${_getColumnLetter(4)}$row'))
            .value = TextCellValue(date);
        sheet.cell(CellIndex.indexByString('${_getColumnLetter(5)}$row'))
            .value = TextCellValue(time);

        // 用户
        sheet.cell(CellIndex.indexByString('${_getColumnLetter(6)}$row'))
            .value = TextCellValue(expense.userNickname ?? '未知用户');

        // 备注（原价信息）
        String remark = '';
        if (expense.hasDiscount) {
          remark = '原价: ¥${expense.originalPrice!.toStringAsFixed(2)}，省: ¥${expense.savedAmount.toStringAsFixed(2)}';
        }
        sheet.cell(CellIndex.indexByString('${_getColumnLetter(7)}$row'))
            .value = TextCellValue(remark);
      }

      // 设置列宽
      sheet.setColumnWidth(0, 8);   // 序号
      sheet.setColumnWidth(1, 12);  // 类型
      sheet.setColumnWidth(2, 12);  // 金额
      sheet.setColumnWidth(3, 20);  // 标签
      sheet.setColumnWidth(4, 14);  // 日期
      sheet.setColumnWidth(5, 10);  // 时间
      sheet.setColumnWidth(6, 12);  // 用户
      sheet.setColumnWidth(7, 30);  // 备注

      // 保存文件
      final bytes = excel.encode();
      if (bytes == null) {
        ToastUtil.showError('生成Excel失败');
        return false;
      }

      final file = File(outputPath);
      await file.writeAsBytes(bytes);

      ToastUtil.showSuccess('导出成功: $outputPath');
      return true;
    } catch (e) {
      ToastUtil.showError('导出失败: $e');
      return false;
    }
  }

  /// 选择保存路径
  static Future<String?> _pickSavePath(String defaultName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: '选择保存位置',
      fileName: '$defaultName.xlsx',
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    return result;
  }

  /// 获取Excel列字母（A, B, C, ...）
  static String _getColumnLetter(int index) {
    return String.fromCharCode(65 + index);
  }
}
