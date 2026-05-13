import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/charts_data_node.dart';
import 'package:journal_windows/services/charts_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/utils/toast_util.dart';

class ChartsController extends GetxController {
  final ChartsService chartsService = ChartsService.to;
  final ActivityService activityService = ActivityService.to;

  final isLoading = false.obs;
  final selectedPeriod = 'week'.obs;
  final selectedActivity = Rx<Activity?>(null);

  final selectedYear = DateTime.now().year.obs;
  final selectedMonth = DateTime.now().month.obs;
  final selectedWeekOffset = 0.obs;

  final chartDisplayMode = 'both'.obs;
  final typeDisplayMode = 'expense'.obs;

  final periodExpenses = <MapEntry<String, double>>[].obs;
  final periodIncome = <MapEntry<String, double>>[].obs;
  final typeExpenses = <ChartsDataNode>[].obs;

  @override
  void onInit() {
    super.onInit();
    selectedActivity.value = activityService.currentActivity.value;
    loadData();

    ever(activityService.currentActivity, (Activity? activity) {
      if (activity != null && selectedActivity.value == null) {
        selectedActivity.value = activity;
        loadData();
      }
    });
  }

  void setPeriod(String period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;
      loadData();
    }
  }

  void setYear(int year) {
    if (selectedYear.value != year) {
      selectedYear.value = year;
      loadData();
    }
  }

  void setMonth(int month) {
    if (selectedMonth.value != month) {
      selectedMonth.value = month;
      loadData();
    }
  }

  void setWeekOffset(int offset) {
    if (selectedWeekOffset.value != offset) {
      selectedWeekOffset.value = offset;
      loadData();
    }
  }

  void setWeekByDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final startOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    
    final selectedDate = DateTime(date.year, date.month, date.day);
    final selectedWeekday = selectedDate.weekday;
    final startOfSelectedWeek = selectedDate.subtract(Duration(days: selectedWeekday - 1));
    
    final difference = startOfSelectedWeek.difference(startOfCurrentWeek).inDays;
    final offset = difference ~/ 7;
    
    selectedWeekOffset.value = offset;
    loadData();
  }

  DateTime getSelectedWeekStartDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final startOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    return startOfCurrentWeek.add(Duration(days: selectedWeekOffset.value * 7));
  }

  void previousWeek() {
    selectedWeekOffset.value--;
    loadData();
  }

  void nextWeek() {
    selectedWeekOffset.value++;
    loadData();
  }

  void previousMonth() {
    if (selectedMonth.value == 1) {
      selectedMonth.value = 12;
      selectedYear.value--;
    } else {
      selectedMonth.value--;
    }
    loadData();
  }

  void nextMonth() {
    if (selectedMonth.value == 12) {
      selectedMonth.value = 1;
      selectedYear.value++;
    } else {
      selectedMonth.value++;
    }
    loadData();
  }

  void previousYear() {
    selectedYear.value--;
    loadData();
  }

  void nextYear() {
    selectedYear.value++;
    loadData();
  }

  String getSelectedTimeDescription() {
    switch (selectedPeriod.value) {
      case 'week':
        return getWeekDescription();
      case 'month':
        return '${selectedYear.value}年${selectedMonth.value}月';
      case 'year':
        return '${selectedYear.value}年';
      default:
        return '';
    }
  }

  String getWeekDescription() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday;
    final startOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    
    final startOfSelectedWeek = startOfCurrentWeek.add(Duration(days: selectedWeekOffset.value * 7));
    final endOfSelectedWeek = startOfSelectedWeek.add(const Duration(days: 6));
    
    if (selectedWeekOffset.value == 0) {
      return '本周';
    } else if (selectedWeekOffset.value == -1) {
      return '上周';
    } else if (selectedWeekOffset.value == 1) {
      return '下周';
    } else {
      return '${startOfSelectedWeek.month}/${startOfSelectedWeek.day} - ${endOfSelectedWeek.month}/${endOfSelectedWeek.day}';
    }
  }

  void selectActivity(Activity? activity) {
    selectedActivity.value = activity;
    loadData();
  }

  Future<void> loadData() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    try {
      if (selectedActivity.value != null) {
        await _loadSingleActivityData(selectedActivity.value!.activityId);
      } else {
        await _loadAllActivitiesData();
      }
    } catch (e) {
      print('加载统计数据失败: $e');
      ToastUtil.showError('加载统计数据失败');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSingleActivityData(String activityId) async {
    String? startDate;
    int? year;
    int? month;

    switch (selectedPeriod.value) {
      case 'week':
        startDate = DateFormat('yyyy-MM-dd').format(getSelectedWeekStartDate());
        break;
      case 'month':
        year = selectedYear.value;
        month = selectedMonth.value;
        break;
      case 'year':
        year = selectedYear.value;
        break;
    }

    final result = await chartsService.getAggregate(
      activityId: activityId,
      period: selectedPeriod.value,
      year: year,
      month: month,
      startDate: startDate,
      typeMode: typeDisplayMode.value,
    );

    if (result != null) {
      periodExpenses.value = result.expenses
          .map((e) => MapEntry(e.name, e.value))
          .toList();
      periodIncome.value = result.income
          .map((e) => MapEntry(e.name, e.value))
          .toList();
      typeExpenses.value = result.types;
    } else {
      periodExpenses.clear();
      periodIncome.clear();
      typeExpenses.clear();
    }
  }

  Future<void> _loadAllActivitiesData() async {
    final allActivities = [
      ...activityService.myActivities,
      ...activityService.joinedActivities,
    ];

    if (allActivities.isEmpty) {
      periodExpenses.clear();
      periodIncome.clear();
      typeExpenses.clear();
      return;
    }

    final allExpenses = <MapEntry<String, double>>[];
    final allIncome = <MapEntry<String, double>>[];
    final allTypes = <String, double>{};

    String? startDate;
    int? year;
    int? month;

    switch (selectedPeriod.value) {
      case 'week':
        startDate = DateFormat('yyyy-MM-dd').format(getSelectedWeekStartDate());
        break;
      case 'month':
        year = selectedYear.value;
        month = selectedMonth.value;
        break;
      case 'year':
        year = selectedYear.value;
        break;
    }

    for (final activity in allActivities) {
      final result = await chartsService.getAggregate(
        activityId: activity.activityId,
        period: selectedPeriod.value,
        year: year,
        month: month,
        startDate: startDate,
        typeMode: typeDisplayMode.value,
      );

      if (result != null) {
        _mergeData(allExpenses, result.expenses);
        _mergeData(allIncome, result.income);
        for (final type in result.types) {
          allTypes[type.name] = (allTypes[type.name] ?? 0) + type.value;
        }
      }
    }

    periodExpenses.value = allExpenses;
    periodIncome.value = allIncome;
    typeExpenses.value = allTypes.entries
        .map((e) => ChartsDataNode(name: e.key, value: e.value))
        .toList();
  }

  void _mergeData(List<MapEntry<String, double>> target, List<ChartsDataNode> source) {
    if (target.isEmpty) {
      target.addAll(source.map((e) => MapEntry(e.name, e.value)));
      return;
    }

    for (int i = 0; i < source.length && i < target.length; i++) {
      target[i] = MapEntry(target[i].key, target[i].value + source[i].value);
    }
  }

  void setChartDisplayMode(String mode) {
    if (chartDisplayMode.value != mode) {
      chartDisplayMode.value = mode;
    }
  }

  void setTypeDisplayMode(String mode) {
    if (typeDisplayMode.value != mode) {
      typeDisplayMode.value = mode;
      loadData();
    }
  }

  double getTotalExpense() {
    return periodExpenses.fold(0.0, (sum, e) => sum + e.value);
  }

  double getTotalIncome() {
    return periodIncome.fold(0.0, (sum, e) => sum + e.value);
  }

  double getCurrentPeriodExpense() {
    return periodExpenses.fold(0.0, (sum, e) => sum + e.value);
  }

  double getCurrentPeriodIncome() {
    return periodIncome.fold(0.0, (sum, e) => sum + e.value);
  }

  double getAverageExpense() {
    final total = getCurrentPeriodExpense();
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

  String getProgressText() {
    switch (selectedPeriod.value) {
      case 'week':
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekday = today.weekday;
        final startOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
        final startOfSelectedWeek = startOfCurrentWeek.add(Duration(days: selectedWeekOffset.value * 7));
        
        if (selectedWeekOffset.value == 0) {
          return '本周第${now.weekday}天';
        } else {
          final totalDays = 7;
          final endOfSelectedWeek = startOfSelectedWeek.add(const Duration(days: 6));
          final isCurrentWeek = now.isAfter(startOfSelectedWeek.subtract(const Duration(days: 1))) && 
                                 now.isBefore(endOfSelectedWeek.add(const Duration(days: 1)));
          if (isCurrentWeek) {
            return '第${now.weekday}天';
          }
          return '$totalDays天';
        }
      case 'month':
        final daysInMonth = DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;
        final now = DateTime.now();
        if (selectedYear.value == now.year && selectedMonth.value == now.month) {
          return '${now.day}/$daysInMonth天';
        }
        return '$daysInMonth天';
      case 'year':
        final totalDays = selectedYear.value % 4 == 0 ? 366 : 365;
        final now = DateTime.now();
        if (selectedYear.value == now.year) {
          final currentDay = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
          return '$currentDay/$totalDays天';
        }
        return '$totalDays天';
      default:
        return '';
    }
  }
}
