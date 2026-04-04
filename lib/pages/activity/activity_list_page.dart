import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/pages/activity/activity_list_controller.dart';
import 'package:journal_windows/pages/activity/activity_page.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/excel_export_service.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 账本列表页面
class ActivityListPage extends StatelessWidget {
  const ActivityListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ActivityListController());

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, controller),
          Expanded(child: _buildContent(context, controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.dialog(
            const ActivityPage(isDialog: true),
          );
          if (result != null) {
            await controller.loadActivities();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('创建账本'),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context, ActivityListController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            '账本管理',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新',
            onPressed: () => controller.loadActivities(),
          ),
          const Spacer(),
          SizedBox(
            width: 250,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: '搜索账本ID加入',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => _joinActivity(controller),
                  tooltip: '加入账本',
                ),
              ),
              onSubmitted: (_) => _joinActivity(controller),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建内容
  Widget _buildContent(BuildContext context, ActivityListController controller) {
    return Obx(() => DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.black87,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: '我的账本'),
                Tab(text: '加入的账本'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActivityList(context, controller.myActivities, controller, true),
                _buildActivityList(context, controller.joinedActivities, controller, false),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  /// 构建账本列表
  Widget _buildActivityList(BuildContext context, RxList<Activity> activities, ActivityListController controller, bool isOwner) {
    // 确保访问 .value 触发依赖追踪
    final isLoading = controller.isLoading.value;
    final activityList = activities.toList();
    
    if (isLoading && activityList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activityList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOwner ? Icons.folder_open : Icons.group_add,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isOwner ? '暂无账本' : '暂无加入的账本',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.loadActivities(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activityList.length,
        itemBuilder: (context, index) {
          final activity = activityList[index];
          return _buildActivityCard(context, activity, controller, isOwner);
        },
      ),
    );
  }

  /// 构建账本卡片
  Widget _buildActivityCard(BuildContext context, Activity activity, ActivityListController controller, bool isOwner) {
    // 判断当前用户是否为账本创建者
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Get.dialog(
            ActivityPage(
              isDialog: true,
              isReadOnly: !isCreator, // 非创建者只读
            ),
            arguments: activity,
          );
          if (result != null) {
            await controller.loadActivities();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.activityName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '创建者: ${activity.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActivityActions(activity, controller, isOwner),
                ],
              ),
              const SizedBox(height: 16),
              _buildActivityStats(activity),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建账本操作按钮
  Widget _buildActivityActions(Activity activity, ActivityListController controller, bool isOwner) {
    // 判断当前用户是否为账本创建者
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity.userId == currentUserId;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 导出按钮
        IconButton(
          icon: const Icon(Icons.download_outlined, size: 20),
          onPressed: () => _exportActivityExpenses(activity),
          tooltip: '导出Excel',
          color: Colors.grey[600],
        ),
        // 编辑/查看按钮 - 创建者可编辑，加入者只能查看
        IconButton(
          icon: Icon(
            isCreator ? Icons.edit_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () async {
            final result = await Get.dialog(
              ActivityPage(
                isDialog: true,
                isReadOnly: !isCreator, // 非创建者只读
              ),
              arguments: activity,
            );
            if (result != null) {
              await controller.loadActivities();
            }
          },
          tooltip: isCreator ? '编辑' : '查看',
          color: Colors.grey[600],
        ),
        if (!isOwner)
          IconButton(
            icon: const Icon(Icons.exit_to_app_outlined, size: 20),
            onPressed: () => _confirmExit(activity, controller),
            tooltip: '退出',
            color: Colors.grey[600],
          ),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => _confirmDelete(activity, controller),
            tooltip: '删除',
            color: Colors.red[400],
          ),
      ],
    );
  }

  /// 构建账本统计信息
  Widget _buildActivityStats(Activity activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildStatItem(
            '总支出',
            '¥${(activity.totalExpense ?? 0).toStringAsFixed(2)}',
            Colors.red,
          ),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _buildStatItem(
            '总收入',
            '¥${(activity.totalIncome ?? 0).toStringAsFixed(2)}',
            Colors.green,
          ),
          if (activity.budget != null) ...[
            Container(width: 1, height: 30, color: Colors.grey[300]),
            _buildStatItem(
              '预算',
              '¥${activity.budget!.toStringAsFixed(2)}',
              Colors.blue,
            ),
          ],
          if (activity.remainingBudget != null) ...[
            Container(width: 1, height: 30, color: Colors.grey[300]),
            _buildStatItem(
              '剩余',
              '¥${activity.remainingBudget!.toStringAsFixed(2)}',
              activity.remainingBudget! >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 加入账本
  void _joinActivity(ActivityListController controller) {
    final activityId = controller.searchController.text.trim();
    if (activityId.isEmpty) {
      ToastUtil.showInfo('请输入账本ID');
      return;
    }
    controller.joinActivity(activityId);
    controller.searchController.clear();
  }

  /// 确认退出账本
  void _confirmExit(Activity activity, ActivityListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认退出'),
        content: Text('确定要退出账本"${activity.activityName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.exitActivity(activity.activityId);
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 确认删除账本
  void _confirmDelete(Activity activity, ActivityListController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除账本"${activity.activityName}"吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteActivity(activity.activityId);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 导出账本账单为Excel
  void _exportActivityExpenses(Activity activity) async {
    ToastUtil.showInfo('正在加载账单数据...');

    final expenseService = Get.find<ExpenseService>();
    final List<Expense> allExpenses = [];
    int pageNum = 1;
    const int pageSize = 50;

    while (true) {
      final expenses = await expenseService.getExpenseList(
        activity.activityId,
        pageNum: pageNum,
      );

      if (expenses.isEmpty) break;

      allExpenses.addAll(expenses);

      if (expenses.length < pageSize) break;

      pageNum++;
    }

    if (allExpenses.isEmpty) {
      ToastUtil.showInfo('该账本暂无账单记录');
      return;
    }

    await ExcelExportService.exportExpenses(
      expenses: allExpenses,
      activityName: activity.activityName,
    );
  }
}