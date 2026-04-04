import 'package:get/get.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/services/storage_service.dart';

/// 账单服务
class ExpenseService extends GetxService {
  static ExpenseService get to => Get.find();
  
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  int _currentPage = 1;
  final int _pageSize = 20;

  /// 获取账单列表
  Future<List<Expense>> getExpenseList(String activityId, {int pageNum = 1}) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getExpenseList(activityId),
        queryParameters: {'pageNum': pageNum},
      );
      
      if (result != null) {
        final list = result['list'] as List?;
        if (list != null) {
          return list.map((e) => Expense.fromJson(e)).toList();
        }
      }
    } catch (e) {
      print('获取账单列表失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  /// 加载账单（分页）
  Future<void> loadExpenses(String activityId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      hasMore.value = true;
      expenses.clear();
    }
    
    if (!hasMore.value) return;
    
    final list = await getExpenseList(activityId, pageNum: _currentPage);
    
    if (refresh) {
      expenses.value = list;
    } else {
      expenses.addAll(list);
    }
    
    hasMore.value = list.length >= _pageSize;
    if (hasMore.value) {
      _currentPage++;
    }
  }

  /// 创建账单
  Future<Expense?> createExpense(Expense expense) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.post<Map<String, dynamic>>(
        ApiConfig.createExpense(),
        data: expense.toJson(),
      );
      
      if (result != null) {
        return Expense.fromJson(result);
      }
    } catch (e) {
      print('创建账单失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// 创建账单（当前账本）
  Future<Expense?> createExpenseCurrent(Expense expense) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.post<Map<String, dynamic>>(
        ApiConfig.createExpenseCurrent(),
        data: expense.toJson(),
      );
      
      if (result != null) {
        return Expense.fromJson(result);
      }
    } catch (e) {
      print('创建账单失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// 更新账单
  Future<bool> updateExpense(Expense expense) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.patch<Map<String, dynamic>>(
        ApiConfig.updateExpense(),
        data: expense.toJson(),
      );
      return result != null;
    } catch (e) {
      print('更新账单失败: $e');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  /// 删除账单
  Future<bool> deleteExpense(String expenseId, String activityId) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.delete<Map<String, dynamic>>(
        ApiConfig.deleteExpense(expenseId, activityId),
      );
      return result != null;
    } catch (e) {
      print('删除账单失败: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 清理缓存 - 退出登录时调用
  void clearCache() {
    expenses.clear();
    isLoading.value = false;
    hasMore.value = true;
    _currentPage = 1;
  }
}
