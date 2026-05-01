import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:journal_windows/models/expense.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/user.dart';
import 'package:journal_windows/pages/expense/expense_list_controller.dart';
import 'package:journal_windows/pages/expense/add_expense_page.dart';
import 'package:journal_windows/pages/expense/expense_detail_page.dart';
import 'package:journal_windows/pages/activity/activity_page.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/services/excel_export_service.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/widgets/cos_image.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/request/request.dart';
import 'package:flutter/services.dart';

/// 账单列表页面
/// 显示当前账本的账单记录，支持按日期分组、粘性吸顶卡片等功能
class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final controller = Get.put(ExpenseListController());
  final ScrollController _scrollController = ScrollController();

  // 粘性吸顶卡片的展开高度
  static const double _expandedHeight = 280.0;
  // 粘性吸顶卡片的折叠高度
  static const double _collapsedHeight = 80.0;
  // 卡片最小缩放比例
  static const double _minScale = 0.85;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Obx(() {
        final hasActivity = controller.currentActivity.value != null;
        return NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(child: _buildHeader()),
            if (hasActivity)
              SliverPersistentHeader(
                pinned: true,
                delegate: _ActivityCardDelegate(
                  expandedHeight: _expandedHeight,
                  collapsedHeight: _collapsedHeight,
                  minScale: _minScale,
                  controller: controller,
                  onTap: _onActivityCardTap,
                ),
              ),
          ],
          body: _buildExpenseList(),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }

  // ============================================================
  // 顶部标题栏模块
  // ============================================================

  /// 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text('账单记录',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新',
            onPressed: () => controller.loadActivities(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 20),
            tooltip: '导出Excel',
            onPressed: _exportToExcel,
          ),
          const SizedBox(width: 12),
          Flexible(child: _buildGlobalSearchInput()),
          const Spacer(),
          _buildJoinActivityButton(),
          const SizedBox(width: 12),
          Obx(() => _buildActivitySelector()),
        ],
      ),
    );
  }

  /// 构建全局搜索输入框
  Widget _buildGlobalSearchInput() {
    return SizedBox(
      width: 200,
      height: 36,
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索账单',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 18),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _showSearchResults(value.trim());
          }
        },
      ),
    );
  }

  /// 显示搜索结果弹窗
  void _showSearchResults(String keyword) async {
    final results = await ExpenseService.to.searchExpense(keyword);
    
    if (!mounted) return;
    
    if (results.isEmpty) {
      ToastUtil.showInfo('未找到相关账单');
      return;
    }
    
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchDialogHeader(keyword, results.length),
              Flexible(child: _buildSearchResultsList(results)),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建搜索结果弹窗头部
  Widget _buildSearchDialogHeader(String keyword, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3E50),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '搜索 "$keyword" 的结果 ($count 条)',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果列表
  Widget _buildSearchResultsList(List<Expense> results) {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = results[index];
        return _buildSearchResultItem(expense);
      },
    );
  }

  /// 构建单条搜索结果
  Widget _buildSearchResultItem(Expense expense) {
    final isExpense = expense.isExpense;
    final color = isExpense ? Colors.red : Colors.green;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isExpense ? Icons.remove_circle_outline : Icons.add_circle_outline,
          color: color,
          size: 24,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              expense.type,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              expense.label.isNotEmpty ? expense.label : '无备注',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (expense.activityName != null) ...[
            Icon(Icons.folder_outlined, size: 12, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              expense.activityName!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            _formatDate(expense.expenseTime),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${isExpense ? "-" : "+"}¥${expense.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: '跳转到账本',
            child: InkWell(
              onTap: () => _jumpToExpense(expense),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Get.dialog(
          ExpenseDetailPage(
            expense: expense,
            activity: Activity(
              activityId: expense.activityId,
              activityName: expense.activityName ?? '',
              userId: '',
              creatorName: '',
              activated: true,
              createTime: '',
            ),
          ),
        );
      },
    );
  }

  /// 跳转到账单所在账本并定位
  void _jumpToExpense(Expense expense) async {
    Get.back();
    
    final targetActivityId = expense.activityId;
    final targetExpenseId = expense.expenseId;
    
    final targetActivity = controller.activities.firstWhereOrNull(
      (a) => a.activityId == targetActivityId,
    );
    
    if (targetActivity == null) {
      ToastUtil.showError('未找到该账本');
      return;
    }
    
    if (controller.currentActivity.value?.activityId != targetActivityId) {
      await controller.selectActivity(targetActivity);
    }
    
    controller.setHighlightExpenseId(targetExpenseId);
    
    await Future.delayed(const Duration(milliseconds: 500));
    _scrollToExpense(targetExpenseId);
    
    Future.delayed(const Duration(seconds: 3), () {
      controller.clearHighlight();
    });
  }

  /// 滚动到指定账单
  void _scrollToExpense(String expenseId) {
    final index = controller.expenses.indexWhere((e) => e.expenseId == expenseId);
    if (index == -1) {
      ToastUtil.showInfo('该记录不在当前页面，请向下滚动查找');
      return;
    }
    
    final itemHeight = 72.0;
    final headerHeight = 40.0;
    
    int itemIndex = 0;
    final groupedExpenses = _groupExpensesByDate(controller.expenses);
    for (final group in groupedExpenses) {
      final expenses = group['expenses'] as List<Expense>;
      for (final e in expenses) {
        if (e.expenseId == expenseId) {
          final offset = itemIndex * itemHeight + groupedExpenses.indexOf(group) * headerHeight - 100;
          _scrollController.animateTo(
            offset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          return;
        }
        itemIndex++;
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      return '${date.month}月${date.day}日';
    } catch (e) {
      return dateStr.substring(0, 10);
    }
  }

  /// 构建加入账本按钮
  Widget _buildJoinActivityButton() {
    return ElevatedButton.icon(
      onPressed: _showJoinActivityDialog,
      icon: const Icon(Icons.group_add, size: 18),
      label: const Text('加入账本'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D3E50),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// 构建账本选择器
  Widget _buildActivitySelector() {
    final activity = controller.currentActivity;
    final hasActivity = activity.value != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: _showActivitySelector,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              hasActivity ? activity.value!.activityName : '选择账本',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 账单列表模块
  // ============================================================

  /// 构建账单列表
  Widget _buildExpenseList() {
    return Obx(() {
      final isLoading = controller.isLoading.value;
      final expenseList = controller.expenses.toList();
      final hasActivity = controller.currentActivity.value != null;

      if (isLoading && expenseList.isEmpty && hasActivity) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!hasActivity) {
        return _buildEmptyState('请选择一个账本', '点击右上角选择或加入账本');
      }

      if (expenseList.isEmpty) {
        return _buildEmptyState('暂无账单记录', '点击右下角按钮开始记账');
      }

      final groupedExpenses = _groupExpensesByDate(expenseList);

      return RefreshIndicator(
        onRefresh: () => controller.loadExpenses(refresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: groupedExpenses.length,
          itemBuilder: (context, index) {
            final group = groupedExpenses[index];
            return _buildExpenseGroup(
              group['date'] as String,
              group['expenses'] as List<Expense>,
              group['total'] as double,
            );
          },
        ),
      );
    });
  }

  /// 构建空状态提示
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            const SizedBox(height: 24),
            if (title == '请选择一个账本') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Get.dialog<bool>(
                        ActivityPage(isDialog: true, isReadOnly: false),
                      );
                      if (result == true) {
                        controller.loadActivities();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('创建账本'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3E50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _showJoinActivityDialogAndRefresh();
                    },
                    icon: const Icon(Icons.group_add),
                    label: const Text('加入账本'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2D3E50),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 按日期分组账单
  /// 返回包含日期标签、账单列表和当日总计的Map列表
  List<Map<String, dynamic>> _groupExpensesByDate(List<Expense> expenses) {
    final groups = <String, List<Expense>>{};
    for (final expense in expenses) {
      final date = expense.expenseTime.split(' ')[0];
      groups.putIfAbsent(date, () => []).add(expense);
    }

    return groups.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final now = DateTime.now();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final isYesterday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1;

      String dateLabel;
      if (isToday) {
        dateLabel = '今天';
      } else if (isYesterday) {
        dateLabel = '昨天';
      } else {
        dateLabel = DateFormat('MM月dd日').format(date);
      }

      final total = entry.value.fold<double>(
          0, (sum, e) => sum + (e.isExpense ? e.price : -e.price));

      return {'date': dateLabel, 'expenses': entry.value, 'total': total};
    }).toList();
  }

  /// 构建账单分组（按日期）
  Widget _buildExpenseGroup(String date, List<Expense> expenses, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
              Text(
                '${total >= 0 ? '支出' : '收入'} ${total.abs().toStringAsFixed(2)}元',
                style: TextStyle(
                    fontSize: 13,
                    color: total >= 0 ? Colors.red : Colors.green),
              ),
            ],
          ),
        ),
        ...expenses.map((e) => _buildExpenseItem(e)),
      ],
    );
  }

  /// 构建单条账单项
  Widget _buildExpenseItem(Expense expense) {
    final isExpense = expense.isExpense;
    final time = expense.expenseTime.split(' ')[1].substring(0, 5);
    final userName = expense.userNickname ?? '未知用户';

    return Obx(() {
      final isHighlighted = controller.highlightExpenseId.value == expense.expenseId;
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.yellow.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isExpense
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getExpenseIcon(expense.type),
                color: isExpense ? Colors.red : Colors.green),
          ),
          title: Row(
            children: [
              Text(expense.type,
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if (expense.label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.label,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(time,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(userName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
              ],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isExpense ? "-" : "+"}${expense.price.toStringAsFixed(1)}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isExpense ? Colors.red : Colors.green),
              ),
              if (expense.hasDiscount)
                Text('省¥${expense.savedAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 10, color: Colors.orange[600])),
            ],
          ),
          onTap: () => _showExpenseDetail(expense),
        ),
      );
    });
  }

  /// 显示账单详情
  void _showExpenseDetail(Expense expense) async {
    final activity = controller.currentActivity.value;
    if (activity == null) return;

    final result = await Get.dialog<bool>(
      ExpenseDetailPage(expense: expense, activity: activity),
    );
    
    if (result == true) {
      controller.loadExpenses(refresh: true);
    }
  }

  /// 根据账单类型获取对应图标
  IconData _getExpenseIcon(String type) {
    const iconMap = {
      '餐饮': Icons.restaurant,
      '交通': Icons.directions_car,
      '购物': Icons.shopping_bag,
      '娱乐': Icons.movie,
      '医疗': Icons.local_hospital,
      '教育': Icons.school,
      '住房': Icons.home,
      '通讯': Icons.phone,
      '水电': Icons.power,
      '工资': Icons.work,
      '奖金': Icons.card_giftcard,
      '投资': Icons.trending_up,
      '兼职': Icons.schedule,
      '红包': Icons.card_giftcard,
    };
    return iconMap[type] ?? Icons.attach_money;
  }

  // ============================================================
  // 账本选择模块
  // ============================================================

  /// 显示账本选择对话框
  void _showActivitySelector() {
    Get.dialog(
      AlertDialog(
        title: const Text('选择账本'),
        content: Obx(() => SizedBox(
              width: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.activities.length,
                itemBuilder: (context, index) {
                  final activity = controller.activities[index];
                  final isSelected =
                      controller.currentActivity.value?.activityId ==
                          activity.activityId;
                  return ListTile(
                    leading: Icon(Icons.folder,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey),
                    title: Text(activity.activityName),
                    subtitle: activity.budget != null
                        ? Text('预算: ¥${activity.budget!.toStringAsFixed(2)}')
                        : null,
                    trailing: isSelected
                        ? Icon(Icons.check,
                            color: Theme.of(context).primaryColor)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      controller.selectActivity(activity);
                      Get.back();
                    },
                  );
                },
              ),
            )),
      ),
    );
  }

  /// 点击账本卡片的回调，打开账本详情页
  Future<void> _onActivityCardTap() async {
    final activity = controller.currentActivity.value;
    if (activity == null) return;

    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity.userId == currentUserId;

    final result = await Get.dialog<bool>(
      ActivityPage(isDialog: true, isReadOnly: !isCreator),
      arguments: activity,
    );
    if (result != null) await controller.loadActivities();
  }

  // ============================================================
  // 导出Excel模块
  // ============================================================

  /// 导出账单为Excel
  void _exportToExcel() async {
    final activity = controller.currentActivity.value;
    if (activity == null) {
      ToastUtil.showInfo('请先选择账本');
      return;
    }

    final expenses = controller.expenses.toList();
    if (expenses.isEmpty) {
      ToastUtil.showInfo('当前账本暂无账单记录');
      return;
    }

    await ExcelExportService.exportExpenses(
      expenses: expenses,
      activityName: activity.activityName,
    );
  }

  // ============================================================
  // 添加账单模块
  // ============================================================

  /// 显示添加账单对话框
  void _showAddExpenseDialog(BuildContext context) {
    if (controller.currentActivity.value == null) {
      ToastUtil.showInfo('请先选择账本');
      return;
    }
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: AddExpensePage(
          activity: controller.currentActivity.value!,
          onClose: () => Get.back(),
        ),
      ),
    );
  }

  // ============================================================
  // 加入账本对话框模块
  // ============================================================

  /// 显示加入账本对话框
  void _showJoinActivityDialog() {
    _showJoinActivityDialogInternal();
  }

  /// 显示加入账本对话框并在成功后刷新
  Future<void> _showJoinActivityDialogAndRefresh() async {
    await _showJoinActivityDialogInternal();
    controller.loadActivities();
  }

  /// 内部实现：显示加入账本对话框
  Future<bool> _showJoinActivityDialogInternal() async {
    final textController = TextEditingController();
    final foundActivity = Rx<Activity?>(null);
    final isSearching = false.obs;
    final joinSuccess = false.obs;

    // 从文本中提取邀请码（格式：ac + 16位字母数字）
    String? regInviteId(String? text) {
      if (text == null) return null;
      final reg = RegExp(r'ac[a-zA-Z0-9]{16}');
      return reg.firstMatch(text)?.group(0);
    }

    // 读取剪贴板内容并自动识别邀请码
    void readClipboard() async {
      try {
        final data = await Clipboard.getData('text/plain');
        if (data == null || data.text == null) {
          ToastUtil.showInfo('剪切板为空');
          return;
        }
        final clipboardText = data.text!;
        final inviteId = regInviteId(clipboardText);
        if (inviteId != null) {
          textController.text = inviteId;
          _searchActivity(inviteId, foundActivity, isSearching);
        } else {
          textController.text = clipboardText;
          ToastUtil.showInfo('未识别到有效邀请码，请手动输入');
        }
      } catch (e) {
        ToastUtil.showError('读取剪贴板失败');
      }
    }

    await Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(),
              _buildSearchInput(
                  textController, foundActivity, isSearching, readClipboard),
              const SizedBox(height: 20),
              _buildSearchResult(foundActivity, isSearching),
              const SizedBox(height: 24),
              _buildDialogButtons(textController, foundActivity, isSearching, joinSuccess),
            ],
          ),
        ),
      ),
    );
    
    return joinSuccess.value;
  }

  /// 构建对话框头部
  Widget _buildDialogHeader() {
    return Column(
      children: [
        // 标题栏
        Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Expanded(
              child: Center(
                child: Text('加入账本',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 24),
        // 邀请码标签
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('邀请码 / 口令',
              style: TextStyle(fontSize: 13, color: Colors.white54)),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建搜索输入框
  Widget _buildSearchInput(
    TextEditingController textController,
    Rx<Activity?> foundActivity,
    RxBool isSearching,
    VoidCallback readClipboard,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 输入框
        TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            hintText: '粘贴或输入邀请码',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.5), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => foundActivity.value = null,
        ),
        const SizedBox(height: 12),
        // 从剪贴板读取按钮
        GestureDetector(
          onTap: readClipboard,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.content_paste, size: 16, color: Colors.white.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text('从剪贴板读取', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建搜索结果展示区域
  Widget _buildSearchResult(Rx<Activity?> foundActivity, RxBool isSearching) {
    return Obx(() {
      if (isSearching.value) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: const Center(child: CircularProgressIndicator(color: Colors.white54)),
        );
      }

      final activity = foundActivity.value;
      if (activity != null) {
        // 找到账本，显示账本卡片
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: Column(
            children: [
              // 账本图标
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.book, size: 32, color: const Color(0xFF2D3E50)),
                ),
              ),
              const SizedBox(height: 16),
              // 账本名称
              Text(activity.activityName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              // 创建者标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '由 ${activity.creatorName} 创建',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      }

      // 未找到账本，显示提示
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 48, color: Colors.white.withValues(alpha: 0.25)),
              const SizedBox(height: 16),
              Text('输入邀请码以查找账本',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.4))),
            ],
          ),
        ),
      );

    });
  }

  /// 构建对话框底部按钮
  Widget _buildDialogButtons(
    TextEditingController textController,
    Rx<Activity?> foundActivity,
    RxBool isSearching,
    RxBool joinSuccess,
  ) {
    return Obx(() {
      final hasData = foundActivity.value != null;
      final isEnabled = !isSearching.value && (hasData || textController.text.isNotEmpty);
      
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  if (hasData) {
                    _joinActivity(textController.text, joinSuccess);
                  } else {
                    _searchActivity(textController.text, foundActivity, isSearching);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasData ? Colors.white : Colors.white.withValues(alpha: 0.15),
            foregroundColor: const Color(0xFF2D3E50),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            hasData ? '确认加入' : '查找账本',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: hasData ? const Color(0xFF2D3E50) : Colors.white.withValues(alpha: isEnabled ? 0.9 : 0.3),
            ),
          ),
        ),
      );
    });
  }

  /// 搜索账本
  void _searchActivity(String activityId, Rx<Activity?> foundActivity,
      RxBool isSearching) async {
    final reg = RegExp(r'ac[a-zA-Z0-9]{16}');
    final inviteId = reg.firstMatch(activityId)?.group(0);
    if (inviteId == null) {
      ToastUtil.showError('无效的邀请码格式');
      return;
    }

    isSearching.value = true;
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
          ApiConfig.searchActivity(inviteId));
      foundActivity.value = result != null ? Activity.fromJson(result) : null;
    } catch (e) {
      ToastUtil.showError('未找到该账本');
      foundActivity.value = null;
    } finally {
      isSearching.value = false;
    }
  }

  /// 加入账本
  void _joinActivity(String text, RxBool joinSuccess) async {
    final reg = RegExp(r'ac[a-zA-Z0-9]{16}');
    final inviteId = reg.firstMatch(text)?.group(0);
    if (inviteId == null) {
      ToastUtil.showError('无效的邀请码格式');
      return;
    }

    final activityService = Get.find<ActivityService>();
    final expenseController = Get.find<ExpenseListController>();

    bool success = false;
    String errorMsg = '';

    await activityService.joinActivity(
      inviteId,
      onSuccess: (msg) => success = true,
      onFail: (msg) => errorMsg = msg,
    );

    if (success) {
      joinSuccess.value = true;
      Get.back();
      ToastUtil.showSuccess('加入账本成功');

      await activityService.getMyActivities();
      await activityService.getJoinedActivities();

      final allActivities = [
        ...activityService.myActivities,
        ...activityService.joinedActivities
      ];
      final joinedActivity =
          allActivities.firstWhereOrNull((a) => a.activityId == inviteId);

      if (joinedActivity != null) {
        await expenseController.selectActivity(joinedActivity);
      } else {
        await expenseController.loadActivities();
      }
    } else {
      ToastUtil.showError(errorMsg.isEmpty ? '加入失败' : errorMsg);
    }
  }
}

// ============================================================
// 粘性吸顶账本卡片委托
// ============================================================

/// 粘性吸顶账本卡片委托
/// 实现滚动时卡片的展开/折叠动画效果
class _ActivityCardDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight; // 展开时的高度
  final double collapsedHeight; // 折叠时的高度
  final double minScale; // 最小缩放比例
  final ExpenseListController controller;
  final VoidCallback onTap;

  _ActivityCardDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.minScale,
    required this.controller,
    required this.onTap,
  });

  @override
  double get minExtent => collapsedHeight;

  @override
  double get maxExtent => expandedHeight;

  /// 构建卡片内容
  /// [shrinkOffset] 滚动偏移量，用于计算展开/折叠进度
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 计算折叠进度 (0.0 = 完全展开, 1.0 = 完全折叠)
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    // 计算缩放比例
    final scale = 1.0 - (progress * (1.0 - minScale));

    return Obx(() {
      final activity = controller.currentActivity.value;
      // 如果没有账本，返回空容器（实际上这种情况不会发生，因为父组件已经判断过了）
      if (activity == null) return const SizedBox.shrink();

      return _buildActivityCard(activity, progress, scale);
    });
  }

  // ------------------------------------------------------------
  // 卡片主体
  // ------------------------------------------------------------

  /// 构建账本卡片主体
  /// [progress] 折叠进度，用于控制内容显示/隐藏
  /// [scale] 缩放比例，用于卡片缩放动画
  Widget _buildActivityCard(Activity activity, double progress, double scale) {
    final totalExpense = activity.totalExpense ?? 0;
    final totalIncome = activity.totalIncome ?? 0;
    final budget = activity.budget ?? 0;
    final remainingBudget = activity.remainingBudget ?? 0;
    // 计算预算使用百分比
    final budgetPercent =
        budget > 0 ? (totalExpense / budget * 100).clamp(0, 100) : 0.0;
    final currentUserId = UserService.to.currentUser.value?.userId ?? '';
    final isCreator = activity.userId == currentUserId;
    // 计算当前卡片高度
    final currentExtent = (maxExtent - (maxExtent - minExtent) * progress)
        .clamp(minExtent, maxExtent);

    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: currentExtent - 16,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.identity()..scale(scale),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF2D3E50),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCardHeader(activity, progress, scale),
                      if (progress < 0.6) ...[
                        const SizedBox(height: 16),
                        _buildExpenseSummary(totalExpense, budget, scale),
                        const SizedBox(height: 12),
                        _buildIncomeAndBalance(
                            totalIncome, remainingBudget, scale),
                        if (budget > 0) ...[
                          const SizedBox(height: 12),
                          _buildBudgetProgress(
                              budgetPercent.toDouble(), budget, scale),
                        ],
                      ],
                      if (progress > 0.5) ...[
                        const SizedBox(height: 8),
                        _buildTapHint(isCreator, scale),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 卡片头部（图标、名称、成员头像）
  // ------------------------------------------------------------

  /// 构建卡片头部（账本图标、名称、成员头像）
  Widget _buildCardHeader(Activity activity, double progress, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildActivityIcon(activity, scale),
            const SizedBox(width: 12),
            _buildActivityInfo(activity, progress, scale),
          ],
        ),
        if (progress < 0.7) _buildMemberAvatars(activity, scale),
      ],
    );
  }

  /// 构建账本图标（显示账本名称首字）
  Widget _buildActivityIcon(Activity activity, double scale) {
    return Container(
      width: 40 * scale,
      height: 40 * scale,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          activity.activityName.isNotEmpty
              ? activity.activityName.substring(0, 1)
              : '?',
          style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
      ),
    );
  }

  /// 构建账本信息（名称和标签）
  Widget _buildActivityInfo(Activity activity, double progress, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.activityName,
          style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
        if (progress < 0.5) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('当前账本',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ),
        ],
      ],
    );
  }

  /// 构建成员头像列表（最多显示3个，超出显示+N）
  Widget _buildMemberAvatars(Activity activity, double scale) {
    final userList = activity.userList ?? [];
    final displayUsers = userList.take(3).toList();
    final remainingCount = userList.length > 3 ? userList.length - 3 : 0;

    return SizedBox(
      width: displayUsers.length * 20.0 * scale + 40 * scale,
      height: 32 * scale,
      child: Stack(
        children: [
          for (int i = 0; i < displayUsers.length; i++)
            Positioned(
                left: i * 20.0 * scale,
                child: _buildUserAvatar(displayUsers[i], scale)),
          if (remainingCount > 0)
            Positioned(
                left: displayUsers.length * 20.0 * scale,
                child: _buildRemainingCount(remainingCount, scale)),
          Positioned(
            left: (displayUsers.length + (remainingCount > 0 ? 1 : 0)) *
                20.0 *
                scale,
            child: _buildAddButton(scale, activity),
          ),
        ],
      ),
    );
  }

  /// 构建单个用户头像
  Widget _buildUserAvatar(User user, double scale) {
    final hasAvatar = user.avatarUrl.isNotEmpty;
    if (hasAvatar) {
      return Container(
        width: 32 * scale,
        height: 32 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2D3E50), width: 2),
        ),
        child: ClipOval(
          child: CosImage(
            cosPath: user.avatarUrl,
            width: 32 * scale,
            height: 32 * scale,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      decoration: BoxDecoration(
        color: Colors.primaries[user.userId.hashCode % Colors.primaries.length],
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2D3E50), width: 2),
      ),
      child: Center(
        child: Text(
          user.nickname.isNotEmpty ? user.nickname.substring(0, 1) : '?',
          style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 构建剩余人数提示（+N）
  Widget _buildRemainingCount(int count, double scale) {
    return Container(
      width: 32 * scale,
      height: 32 * scale,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2D3E50), width: 2),
      ),
      child: Center(
        child: Text('+$count',
            style: TextStyle(
                fontSize: 11 * scale,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// 构建添加成员按钮
  Widget _buildAddButton(double scale, Activity activity) {
    return GestureDetector(
      onTap: () {
        // 阻止事件冒泡，防止触发卡片的点击事件
        // 显示邀请码对话框
        _showInviteCodeDialog(activity);
      },
      child: Container(
        width: 32 * scale,
        height: 32 * scale,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2D3E50), width: 2),
        ),
        child: Icon(Icons.add, size: 16 * scale, color: Colors.white70),
      ),
    );
  }

  /// 显示邀请码对话框
  void _showInviteCodeDialog(Activity activity) {
    final inviteCode = activity.activityId;
    final userList = activity.userList ?? [];
    
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF2D3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('邀请成员',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 20),
              
              // 账本信息卡片
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          activity.activityName.isNotEmpty ? activity.activityName.substring(0, 1) : '?',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('邀请加入', style: TextStyle(fontSize: 12, color: Colors.white54)),
                          const SizedBox(height: 2),
                          Text(activity.activityName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 邀请码区域
              const Text('专属邀请码（点击复制）',
                  style: TextStyle(fontSize: 13, color: Colors.white54)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ToastUtil.showSuccess('邀请码已复制');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Text(
                        inviteCode.length > 16 ? '${inviteCode.substring(0, 16)}...' : inviteCode,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 已加入成员
              if (userList.isNotEmpty) ...[
                Row(
                  children: [
                    Text('已加入成员 ${userList.length} 人',
                        style: const TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: userList.length,
                    itemBuilder: (context, index) {
                      final user = userList[index];
                      final isCreator = user.userId == activity.userId;
                      final hasAvatar = user.avatarUrl.isNotEmpty;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: ClipOval(
                                child: hasAvatar
                                    ? CosImage(
                                        cosPath: user.avatarUrl,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.amber,
                                        child: Center(
                                          child: Text(
                                            user.nickname.isNotEmpty ? user.nickname.substring(0, 1) : '?',
                                            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(user.nickname,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                                      if (isCreator) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('创建者', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('1970-01-01 加入',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 底部分享按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: inviteCode));
                    ToastUtil.showSuccess('邀请码已复制，可分享给好友');
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('分享完整邀请码'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2D3E50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 统计信息（支出汇总、收入结余、预算进度）
  // ------------------------------------------------------------

  /// 构建支出汇总（总支出金额）
  Widget _buildExpenseSummary(
      double totalExpense, double budget, double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('总支出',
            style: TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(width: 8),
        Text(
          '¥${totalExpense.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 32 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        if (budget > 0) ...[
          const SizedBox(width: 8),
          Text('/ $budget',
              style: TextStyle(
                  fontSize: 18 * scale,
                  color: Colors.white.withValues(alpha: 0.6))),
        ],
      ],
    );
  }

  /// 构建收入和结余信息
  Widget _buildIncomeAndBalance(
      double totalIncome, double remainingBudget, double scale) {
    return Row(
      children: [
        Expanded(
            child: _buildMiniStat(
                '收入', totalIncome.toStringAsFixed(2), Colors.green, scale)),
        Container(
            width: 1,
            height: 40 * scale,
            color: Colors.white.withValues(alpha: 0.1)),
        Expanded(
          child: _buildMiniStat(
            '结余',
            remainingBudget.toStringAsFixed(2),
            remainingBudget >= 0 ? Colors.blue : Colors.red,
            scale,
          ),
        ),
      ],
    );
  }

  /// 构建迷你统计项（收入/结余）
  Widget _buildMiniStat(String label, String value, Color color, double scale) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13 * scale,
                color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }

  /// 构建预算进度条
  Widget _buildBudgetProgress(
      double budgetPercent, double budget, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('总花销进度',
                style: TextStyle(fontSize: 13, color: Colors.white70)),
            Text('${budgetPercent.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: budgetPercent / 100,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                budgetPercent > 90 ? Colors.red : Colors.green),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '总预算 ¥${budget.toStringAsFixed(2)}',
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // 点击提示
  // ------------------------------------------------------------

  /// 构建点击提示（折叠时显示）
  Widget _buildTapHint(bool isCreator, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isCreator ? Icons.edit : Icons.visibility,
            size: 14 * scale, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 4),
        Text(
          isCreator ? '点击编辑账本' : '点击查看详情',
          style: TextStyle(
              fontSize: 12 * scale, color: Colors.white.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}
