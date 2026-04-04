import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/models/charts_data_node.dart';
import 'package:journal_windows/services/charts_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 图表控制器
class ChartsController extends GetxController {
  final ChartsService chartsService = ChartsService.to;
  final ActivityService activityService = ActivityService.to;
  final ExpenseService expenseService = ExpenseService.to;

  final isLoading = false.obs;
  final selectedPeriod = 'week'.obs; // week, month, year
  final selectedActivity = Rx<Activity?>(null);

  // 图表显示模式: expense(仅支出), income(仅收入), both(两者都显示)
  final chartDisplayMode = 'both'.obs;

  // 分类统计显示模式: expense(支出), income(收入)
  final typeDisplayMode = 'expense'.obs;

  // 所有账单的原始数据（用于聚合统计）
  final allExpenses = <Expense>[].obs;

  // 周期统计数据
  final periodExpenses = <MapEntry<String, double>>[].obs;
  final periodIncome = <MapEntry<String, double>>[].obs;
  final typeExpenses = <ChartsDataNode>[].obs;

  @override
  void onInit() {
    super.onInit();
    // 默认选中当前账本
    selectedActivity.value = activityService.currentActivity.value;
    loadData();

    // 监听当前账本变化
    ever(activityService.currentActivity, (Activity? activity) {
      if (activity != null && selectedActivity.value == null) {
        selectedActivity.value = activity;
        loadData();
      }
    });
  }

  /// 设置统计周期
  void setPeriod(String period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;
      loadData();
    }
  }

  /// 选择账本（null表示所有账本）
  void selectActivity(Activity? activity) {
    selectedActivity.value = activity;
    loadData();
  }

  /// 加载数据
  Future<void> loadData() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    try {
      if (selectedActivity.value != null) {
        // 加载单个账本数据
        await _loadSingleActivityData(selectedActivity.value!.activityId);
      } else {
        // 加载所有账本数据
        await _loadAllActivitiesData();
      }
    } catch (e) {
      print('加载统计数据失败: $e');
      ToastUtil.showError('加载统计数据失败');
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载单个账本数据
  Future<void> _loadSingleActivityData(String activityId) async {
    // 加载周统计数据（从后端）
    await chartsService.loadAllCharts(activityId);

    // 获取账本的所有账单（用于按月/年统计）
    allExpenses.clear();
    // 获取所有分页数据
    int page = 1;
    const int pageSize = 20;
    while (true) {
      final expenses = await expenseService.getExpenseList(activityId, pageNum: page);
      if (expenses.isEmpty || expenses.length < pageSize) {
        // 返回数据不足一页，说明是最后一页
        allExpenses.addAll(expenses);
        break;
      }
      allExpenses.addAll(expenses);
      page++;
    }

    // 根据周期聚合数据
    _aggregateDataByPeriod();

    // 分类统计
    typeExpenses.value = chartsService.typeExpenses;
  }

  /// 加载所有账本数据
  Future<void> _loadAllActivitiesData() async {
    allExpenses.clear();
    final allActivities = [
      ...activityService.myActivities,
      ...activityService.joinedActivities,
    ];

    // 获取所有账单的账单数据
    const int pageSize = 20;
    for (final activity in allActivities) {
      int page = 1;
      while (true) {
        final expenses = await expenseService.getExpenseList(activity.activityId, pageNum: page);
        if (expenses.isEmpty || expenses.length < pageSize) {
          allExpenses.addAll(expenses);
          break;
        }
        allExpenses.addAll(expenses);
        page++;
      }
    }

    // 聚合数据
    _aggregateDataByPeriod();

    // 按类型聚合（所有账本）
    _aggregateTypeData();
  }

  /// 按周期聚合数据
  void _aggregateDataByPeriod() {
    periodExpenses.clear();
    periodIncome.clear();

    switch (selectedPeriod.value) {
      case 'week':
        _aggregateByWeek();
        break;
      case 'month':
        _aggregateByMonth();
        break;
      case 'year':
        _aggregateByYear();
        break;
    }
  }

  /// 按周聚合
  void _aggregateByWeek() {
    final now = DateTime.now();

    // 获取本周的开始（周一）
    final weekday = now.weekday; // 1=Monday, 7=Sunday
    final startOfWeek = now.subtract(Duration(days: weekday - 1));

    // 初始化本周每天的数据
    final expenseMap = <String, double>{};
    final incomeMap = <String, double>{};
    final dateLabels = <String, String>{}; // key -> display label

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final label = DateFormat('M-d').format(day); // 显示为 "3-26" 格式
      expenseMap[key] = 0;
      incomeMap[key] = 0;
      dateLabels[key] = label;
    }

    // 聚合数据
    for (final expense in allExpenses) {
      try {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(expense.expenseTime);
        final key = DateFormat('yyyy-MM-dd').format(date);

        if (expenseMap.containsKey(key)) {
          if (expense.isExpense) {
            expenseMap[key] = (expenseMap[key] ?? 0) + expense.price;
          } else {
            incomeMap[key] = (incomeMap[key] ?? 0) + expense.price;
          }
        }
      } catch (e) {
        // 忽略解析错误的日期
      }
    }

    // 转换为列表并排序
    final sortedKeys = expenseMap.keys.toList()..sort();
    for (final key in sortedKeys) {
      final label = dateLabels[key] ?? key;
      periodExpenses.add(MapEntry(label, expenseMap[key] ?? 0));
      periodIncome.add(MapEntry(label, incomeMap[key] ?? 0));
    }
  }

  /// 按月聚合（显示当月的每一天）
  void _aggregateByMonth() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 获取当月的天数
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    // 初始化当月的每一天（使用两位格式）
    final expenseMap = <String, double>{};
    final incomeMap = <String, double>{};

    for (int i = 1; i <= daysInMonth; i++) {
      final key = i.toString().padLeft(2, '0'); // 显示为 "01", "02", ... "31"
      expenseMap[key] = 0;
      incomeMap[key] = 0;
    }

    // 聚合数据
    for (final expense in allExpenses) {
      try {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(expense.expenseTime);

        // 只统计当前年月的账单
        if (date.year == currentYear && date.month == currentMonth) {
          final key = date.day.toString().padLeft(2, '0'); // 使用两位格式

          if (expense.isExpense) {
            expenseMap[key] = (expenseMap[key] ?? 0) + expense.price;
          } else {
            incomeMap[key] = (incomeMap[key] ?? 0) + expense.price;
          }
        }
      } catch (e) {
        // 忽略解析错误的日期
      }
    }

    periodExpenses.addAll(expenseMap.entries);
    periodIncome.addAll(incomeMap.entries);
  }

  /// 按年聚合（显示1-12月）
  void _aggregateByYear() {
    final now = DateTime.now();
    final currentYear = now.year;

    // 初始化1-12月
    final expenseMap = <String, double>{};
    final incomeMap = <String, double>{};

    for (int i = 1; i <= 12; i++) {
      final key = '$i月'; // 显示为 "1月", "2月", ... "12月"
      expenseMap[key] = 0;
      incomeMap[key] = 0;
    }

    // 聚合数据
    for (final expense in allExpenses) {
      try {
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(expense.expenseTime);

        // 只统计当前年份的账单
        if (date.year == currentYear) {
          final key = '${date.month}月';

          if (expense.isExpense) {
            expenseMap[key] = (expenseMap[key] ?? 0) + expense.price;
          } else {
            incomeMap[key] = (incomeMap[key] ?? 0) + expense.price;
          }
        }
      } catch (e) {
        // 忽略解析错误的日期
      }
    }

    periodExpenses.addAll(expenseMap.entries);
    periodIncome.addAll(incomeMap.entries);
  }

  /// 按类型聚合数据（所有账本时使用）
  void _aggregateTypeData() {
    _aggregateTypeDataByMode(typeDisplayMode.value);
  }

  /// 根据模式聚合分类数据
  void _aggregateTypeDataByMode(String mode) {
    final typeMap = <String, double>{};

    for (final expense in allExpenses) {
      final isExpenseItem = expense.isExpense;
      final shouldInclude = mode == 'expense' ? isExpenseItem : !isExpenseItem;

      if (shouldInclude) {
        typeMap[expense.type] = (typeMap[expense.type] ?? 0) + expense.price;
      }
    }

    typeExpenses.value = typeMap.entries
        .map((e) => ChartsDataNode(name: e.key, value: e.value))
        .toList();
  }

  /// 设置图表显示模式
  void setChartDisplayMode(String mode) {
    if (chartDisplayMode.value != mode) {
      chartDisplayMode.value = mode;
    }
  }

  /// 设置分类显示模式
  void setTypeDisplayMode(String mode) {
    if (typeDisplayMode.value != mode) {
      typeDisplayMode.value = mode;
      _aggregateTypeDataByMode(mode);
    }
  }

  /// 获取总支出（所有数据）
  double getTotalExpense() {
    return allExpenses
        .where((e) => e.isExpense)
        .fold(0.0, (sum, e) => sum + e.price);
  }

  /// 获取总收入（所有数据）
  double getTotalIncome() {
    return allExpenses
        .where((e) => !e.isExpense)
        .fold(0.0, (sum, e) => sum + e.price);
  }

  /// 获取当前周期支出
  double getCurrentPeriodExpense() {
    return periodExpenses.fold(0.0, (sum, e) => sum + e.value);
  }

  /// 获取当前周期收入
  double getCurrentPeriodIncome() {
    return periodIncome.fold(0.0, (sum, e) => sum + e.value);
  }

  /// 获取平均支出（按周期进度计算）
  double getAverageExpense() {
    final total = getCurrentPeriodExpense();
    final now = DateTime.now();
    double progress = 0;

    switch (selectedPeriod.value) {
      case 'week':
        // 本周已过天数（周一为第一天）
        progress = now.weekday.toDouble();
        break;
      case 'month':
        // 本月已过天数
        progress = now.day.toDouble();
        break;
      case 'year':
        // 本年的第几天
        progress = now.difference(DateTime(now.year, 1, 1)).inDays + 1.0;
        break;
    }

    if (progress <= 0) progress = 1;
    return total / progress;
  }

  /// 获取平均收入（按周期进度计算）
  double getAverageIncome() {
    final total = getCurrentPeriodIncome();
    final now = DateTime.now();
    double progress = 0;

    switch (selectedPeriod.value) {
      case 'week':
        progress = now.weekday.toDouble();
        break;
      case 'month':
        progress = now.day.toDouble();
        break;
      case 'year':
        progress = now.difference(DateTime(now.year, 1, 1)).inDays + 1.0;
        break;
    }

    if (progress <= 0) progress = 1;
    return total / progress;
  }

  /// 获取周期进度描述
  String getProgressText() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case 'week':
        return '本周第${now.weekday}天';
      case 'month':
        return '${now.day}/${DateTime(now.year, now.month + 1, 0).day}天';
      case 'year':
        final totalDays = now.year % 4 == 0 ? 366 : 365;
        final currentDay = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
        return '$currentDay/$totalDays天';
      default:
        return '';
    }
  }
}
