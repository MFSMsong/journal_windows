import 'package:get/get.dart';
import 'package:journal_windows/models/charts_data_node.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';

/// 图表服务
class ChartsService extends GetxService {
  static ChartsService get to => Get.find();
  
  final RxList<ChartsDataNode> weeklyExpenses = <ChartsDataNode>[].obs;
  final RxList<ChartsDataNode> weeklyIncome = <ChartsDataNode>[].obs;
  final RxList<ChartsDataNode> typeExpenses = <ChartsDataNode>[].obs;
  final RxBool isLoading = false.obs;

  /// 获取周支出统计
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

  /// 获取周收入统计
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

  /// 获取分类统计
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

  /// 加载所有图表数据
  Future<void> loadAllCharts(String activityId) async {
    await Future.wait([
      getWeeklyExpenses(activityId),
      getWeeklyIncome(activityId),
      getTypeExpenses(activityId),
    ]);
  }

  /// 计算总支出
  double getTotalExpense() {
    return weeklyExpenses.fold(0.0, (sum, item) => sum + item.value);
  }

  /// 计算总收入
  double getTotalIncome() {
    return weeklyIncome.fold(0.0, (sum, item) => sum + item.value);
  }

  /// 计算分类总支出
  double getTotalByType() {
    return typeExpenses.fold(0.0, (sum, item) => sum + item.value);
  }

  /// 清理缓存 - 退出登录时调用
  void clearCache() {
    weeklyExpenses.clear();
    weeklyIncome.clear();
    typeExpenses.clear();
    isLoading.value = false;
  }
}
