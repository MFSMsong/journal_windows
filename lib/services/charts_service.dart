import 'package:get/get.dart';
import 'package:journal_windows/models/charts_data_node.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';

class ChartsService extends GetxService {
  static ChartsService get to => Get.find();
  
  final RxList<ChartsDataNode> weeklyExpenses = <ChartsDataNode>[].obs;
  final RxList<ChartsDataNode> weeklyIncome = <ChartsDataNode>[].obs;
  final RxList<ChartsDataNode> typeExpenses = <ChartsDataNode>[].obs;
  final RxBool isLoading = false.obs;

  Future<List<ChartsDataNode>> getWeeklyExpenses(String activityId) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getChartsWeekly(activityId),
      );
      
      if (result != null) {
        weeklyExpenses.value = result.map((e) => ChartsDataNode.fromJson(e)).toList();
        return weeklyExpenses;
      }
    } catch (e) {
      print('获取周支出统计失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  Future<List<ChartsDataNode>> getWeeklyIncome(String activityId) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getChartsWeeklyIncome(activityId),
      );
      
      if (result != null) {
        weeklyIncome.value = result.map((e) => ChartsDataNode.fromJson(e)).toList();
        return weeklyIncome;
      }
    } catch (e) {
      print('获取周收入统计失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  Future<List<ChartsDataNode>> getTypeExpenses(String activityId) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getChartsWeeklyType(activityId),
      );
      
      if (result != null) {
        typeExpenses.value = result.map((e) => ChartsDataNode.fromJson(e)).toList();
        return typeExpenses;
      }
    } catch (e) {
      print('获取分类统计失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  Future<void> loadAllCharts(String activityId) async {
    await Future.wait([
      getWeeklyExpenses(activityId),
      getWeeklyIncome(activityId),
      getTypeExpenses(activityId),
    ]);
  }

  Future<ChartsAggregateResult?> getAggregate({
    required String activityId,
    required String period,
    int? year,
    int? month,
    String? startDate,
    String typeMode = 'expense',
  }) async {
    isLoading.value = true;
    try {
      final queryParams = <String, dynamic>{
        'period': period,
        'typeMode': typeMode,
      };
      
      if (year != null) queryParams['year'] = year;
      if (month != null) queryParams['month'] = month;
      if (startDate != null) queryParams['startDate'] = startDate;

      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getChartsAggregate(activityId),
        queryParameters: queryParams,
      );
      
      if (result != null) {
        return ChartsAggregateResult.fromJson(result);
      }
    } catch (e) {
      print('获取聚合统计失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  double getTotalExpense() {
    return weeklyExpenses.fold(0.0, (sum, item) => sum + item.value);
  }

  double getTotalIncome() {
    return weeklyIncome.fold(0.0, (sum, item) => sum + item.value);
  }

  double getTotalByType() {
    return typeExpenses.fold(0.0, (sum, item) => sum + item.value);
  }

  void clearCache() {
    weeklyExpenses.clear();
    weeklyIncome.clear();
    typeExpenses.clear();
    isLoading.value = false;
  }
}

class ChartsAggregateResult {
  final List<ChartsDataNode> expenses;
  final List<ChartsDataNode> income;
  final List<ChartsDataNode> types;

  ChartsAggregateResult({
    required this.expenses,
    required this.income,
    required this.types,
  });

  factory ChartsAggregateResult.fromJson(Map<String, dynamic> json) {
    return ChartsAggregateResult(
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => ChartsDataNode.fromJson(e))
              .toList() ??
          [],
      income: (json['income'] as List<dynamic>?)
              ?.map((e) => ChartsDataNode.fromJson(e))
              .toList() ??
          [],
      types: (json['types'] as List<dynamic>?)
              ?.map((e) => ChartsDataNode.fromJson(e))
              .toList() ??
          [],
    );
  }
}
