import 'dart:async';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/storage_service.dart';
import 'package:journal_windows/services/websocket_service.dart';
import 'package:journal_windows/constants/message_type.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 账单列表控制器
class ExpenseListController extends GetxController {
  final ExpenseService _expenseService = ExpenseService.to;
  final ActivityService _activityService = ActivityService.to;
  final WebSocketService _webSocketService = WebSocketService.to;
  
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxList<Activity> activities = <Activity>[].obs;
  final Rx<Activity?> currentActivity = Rx<Activity?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxString highlightExpenseId = ''.obs;
  
  int _currentPage = 1;
  final int _pageSize = 20;
  
  StreamSubscription? _wsSubscription;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  /// 初始化数据
  Future<void> _initData() async {
    // 直接引用 ActivityService 的响应式变量，避免复制值
    // 这样 Obx 会正确追踪依赖
    ever(_activityService.currentActivity, (Activity? activity) {
      currentActivity.value = activity;
      if (activity != null) {
        loadExpenses(refresh: true);
      } else {
        // 退出账本后清空账单列表
        expenses.clear();
        hasMore.value = true;
        _currentPage = 1;
      }
    });

    // 监听我的账本变化
    ever(_activityService.myActivities, (List<Activity> list) {
      _updateActivitiesList();
    });

    // 监听加入的账本变化
    ever(_activityService.joinedActivities, (List<Activity> list) {
      _updateActivitiesList();
    });

    // 初始化时加载所有账本
    await loadActivities();

    // 初始化当前值
    currentActivity.value = _activityService.currentActivity.value;

    if (currentActivity.value != null) {
      await loadExpenses(refresh: true);
    }
    
    _subscribeWebSocket();
  }

  void _subscribeWebSocket() {
    _wsSubscription = _webSocketService.messageStream.listen(_handleWebSocketMessage);
    
    ever(currentActivity, (Activity? activity) {
      if (activity != null) {
        _webSocketService.subscribeActivity(activity.activityId);
      }
    });
    
    if (currentActivity.value != null) {
      _webSocketService.subscribeActivity(currentActivity.value!.activityId);
    }
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    final activityId = message.activityId;
    final currentId = currentActivity.value?.activityId;
    
    if (activityId != null && activityId != currentId) {
      return;
    }
    
    switch (message.type) {
      case MessageType.expenseAdd:
        _onExpenseAdd(message.data);
        break;
      case MessageType.expenseUpdate:
        _onExpenseUpdate(message.data);
        break;
      case MessageType.expenseDelete:
        _onExpenseDelete(message.data);
        break;
      case MessageType.activityUpdate:
        _onActivityUpdate(message.data);
        break;
      case MessageType.activityDelete:
        _onActivityDelete(message.data);
        break;
      case MessageType.memberJoin:
      case MessageType.memberExit:
      case MessageType.memberKick:
      case MessageType.memberNicknameUpdate:
        _onMemberChange(message);
        break;
    }
  }

  void _onExpenseAdd(dynamic data) {
    if (data == null) return;
    
    try {
      final expense = Expense.fromJson(data as Map<String, dynamic>);
      expenses.insert(0, expense);
      setHighlightExpenseId(expense.expenseId);
      Future.delayed(const Duration(seconds: 2), clearHighlight);
    } catch (e) {
      // ignore
    }
  }

  void _onExpenseUpdate(dynamic data) {
    if (data == null) return;
    
    try {
      final expense = Expense.fromJson(data as Map<String, dynamic>);
      final index = expenses.indexWhere((e) => e.expenseId == expense.expenseId);
      if (index != -1) {
        expenses[index] = expense;
      }
    } catch (e) {
      // ignore
    }
  }

  void _onExpenseDelete(dynamic data) {
    if (data == null) return;
    
    try {
      final expenseId = (data as Map<String, dynamic>)['expenseId'] as String;
      expenses.removeWhere((e) => e.expenseId == expenseId);
    } catch (e) {
      // ignore
    }
  }

  void _onActivityUpdate(dynamic data) {
    if (data == null) return;
    
    try {
      final activity = Activity.fromJson(data as Map<String, dynamic>);
      if (currentActivity.value?.activityId == activity.activityId) {
        currentActivity.value = activity;
      }
      loadActivities();
    } catch (e) {
      // ignore
    }
  }

  void _onActivityDelete(dynamic data) {
    if (data == null) return;
    
    try {
      final activityId = (data as Map<String, dynamic>)['activityId'] as String;
      if (currentActivity.value?.activityId == activityId) {
        currentActivity.value = null;
        expenses.clear();
        _webSocketService.unsubscribeActivity(activityId);
      }
      loadActivities();
    } catch (e) {
      // ignore
    }
  }

  void _onMemberChange(WebSocketMessage message) {
    loadActivities();
  }

  /// 合并我的账本和加入的账本
  void _updateActivitiesList() {
    final allActivities = <Activity>[];
    allActivities.addAll(_activityService.myActivities);
    allActivities.addAll(_activityService.joinedActivities);
    activities.value = allActivities;
  }

  /// 加载账单
  Future<void> loadExpenses({bool refresh = false}) async {
    if (currentActivity.value == null) return;
    
    if (refresh) {
      _currentPage = 1;
      hasMore.value = true;
      expenses.clear();
    }
    
    if (!hasMore.value) return;
    
    isLoading.value = true;
    try {
      final list = await _expenseService.getExpenseList(
        currentActivity.value!.activityId,
        pageNum: _currentPage,
      );
      
      if (refresh) {
        expenses.value = list;
      } else {
        expenses.addAll(list);
      }
      
      if (list.length >= _pageSize) {
        _currentPage++;
        hasMore.value = true;
      } else {
        hasMore.value = false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// 选择账本
  Future<void> selectActivity(Activity activity) async {
    currentActivity.value = activity;
    _activityService.setCurrentActivity(activity);
    await loadExpenses(refresh: true);
  }

  /// 删除账单
  Future<void> deleteExpense(String expenseId) async {
    if (currentActivity.value == null) return;

    final success = await _expenseService.deleteExpense(
      expenseId,
      currentActivity.value!.activityId,
    );

    if (success) {
      ToastUtil.showSuccess('删除成功');
      await loadActivities();
    }
  }

  /// 清理缓存 - 退出登录时调用
  void clearCache() {
    expenses.clear();
    activities.clear();
    currentActivity.value = null;
    isLoading.value = false;
    hasMore.value = true;
    _currentPage = 1;
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    super.onClose();
  }

  /// 加载账本列表 - 用于刷新
  Future<void> loadActivities() async {
    // 刷新我的账本和加入的账本
    await _activityService.getMyActivities();
    await _activityService.getJoinedActivities();

    // 合并我的账本和加入的账本（_updateActivitiesList 会更新 activities）
    _updateActivitiesList();

    // 如果当前有选中的账本，刷新当前账本的详细信息
    if (currentActivity.value != null) {
      // 从刷新后的列表中查找更新的账本信息
      final updatedActivity = activities.firstWhereOrNull(
        (a) => a.activityId == currentActivity.value!.activityId,
      );
      if (updatedActivity != null) {
        currentActivity.value = updatedActivity;
        _activityService.setCurrentActivity(updatedActivity);
        await loadExpenses(refresh: true);
      } else {
        // 如果当前账本不在列表中（被删除或退出），清空当前账本
        currentActivity.value = null;
        _activityService.currentActivity.value = null;
        StorageService.removeCurrentActivityId();
        expenses.clear();
        hasMore.value = true;
        _currentPage = 1;
      }
    } else if (activities.isNotEmpty) {
      // 如果当前没有选中的账本，且有可用账本，自动选择第一个
      currentActivity.value = activities.first;
      _activityService.setCurrentActivity(activities.first);
      await loadExpenses(refresh: true);
    } else {
      // 没有任何账本，确保数据清空
      expenses.clear();
      hasMore.value = true;
      _currentPage = 1;
    }
  }

  /// 设置需要高亮的账单ID
  void setHighlightExpenseId(String expenseId) {
    highlightExpenseId.value = expenseId;
  }

  /// 清除高亮
  void clearHighlight() {
    highlightExpenseId.value = '';
  }
}