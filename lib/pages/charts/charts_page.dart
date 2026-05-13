import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/charts/charts_controller.dart';

/// 图表统计页面
class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChartsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(controller),
          _buildPeriodSelector(controller),
          Expanded(child: _buildContent(controller)),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(ChartsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            '数据统计',
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
            onPressed: () => controller.loadData(),
          ),
          const Spacer(),
          // 账本选择器
          _buildActivitySelector(controller),
        ],
      ),
    );
  }

  /// 构建账本选择器
  Widget _buildActivitySelector(ChartsController controller) {
    return Obx(() => InkWell(
      onTap: () => _showActivitySelector(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_outlined, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              controller.selectedActivity.value?.activityName ?? '所有账本',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    ));
  }

  /// 构建周期选择器
  Widget _buildPeriodSelector(ChartsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodChip('周', 'week', controller),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodChip('月', 'month', controller),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPeriodChip('年', 'year', controller),
          ),
          const SizedBox(width: 16),
          _buildTimeSelector(controller),
        ],
      ),
    );
  }

  /// 构建时间选择器
  Widget _buildTimeSelector(ChartsController controller) {
    return Obx(() {
      switch (controller.selectedPeriod.value) {
        case 'week':
          return _buildWeekSelector(controller);
        case 'month':
          return _buildMonthSelector(controller);
        case 'year':
          return _buildYearSelector(controller);
        default:
          return const SizedBox.shrink();
      }
    });
  }

  /// 构建周选择器
  Widget _buildWeekSelector(ChartsController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: controller.previousWeek,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        GestureDetector(
          onTap: () => _showWeekPicker(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.getWeekDescription(),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: controller.nextWeek,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 显示周选择器（日期选择）
  Future<void> _showWeekPicker(ChartsController controller) async {
    final selectedDate = await showDatePicker(
      context: Get.context!,
      initialDate: controller.getSelectedWeekStartDate(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('zh', 'CN'),
      helpText: '选择日期',
      confirmText: '确定',
      cancelText: '取消',
    );
    
    if (selectedDate != null) {
      controller.setWeekByDate(selectedDate);
    }
  }

  /// 构建月选择器
  Widget _buildMonthSelector(ChartsController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: controller.previousMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        GestureDetector(
          onTap: () => _showMonthPicker(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${controller.selectedYear.value}年${controller.selectedMonth.value}月',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: controller.nextMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 构建年选择器
  Widget _buildYearSelector(ChartsController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: controller.previousYear,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        GestureDetector(
          onTap: () => _showYearPicker(controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${controller.selectedYear.value}年',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: controller.nextYear,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 显示月份选择器
  void _showMonthPicker(ChartsController controller) {
    int tempYear = controller.selectedYear.value;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('选择月份'),
            content: SizedBox(
              width: 280,
              height: 300,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() => tempYear--);
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '$tempYear年',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() => tempYear++);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final isSelected = controller.selectedYear.value == tempYear && 
                                           controller.selectedMonth.value == month;
                        return InkWell(
                          onTap: () {
                            controller.selectedYear.value = tempYear;
                            controller.setMonth(month);
                            Get.back();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF2D3E50) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$month月',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 显示年份选择器
  void _showYearPicker(ChartsController controller) {
    final currentYear = DateTime.now().year;
    final years = List.generate(21, (index) => currentYear - 10 + index);
    
    Get.dialog(
      AlertDialog(
        title: const Text('选择年份'),
        content: SizedBox(
          width: 280,
          height: 300,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: years.map((year) {
              final isSelected = controller.selectedYear.value == year;
              return InkWell(
                onTap: () {
                  controller.setYear(year);
                  Get.back();
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2D3E50) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$year',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// 构建周期芯片
  Widget _buildPeriodChip(String label, String value, ChartsController controller) {
    return Obx(() {
      final isSelected = controller.selectedPeriod.value == value;
      return GestureDetector(
        onTap: () => controller.setPeriod(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D3E50) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      );
    });
  }

  /// 构建内容
  Widget _buildContent(ChartsController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 总收支卡片
              _buildTotalSummaryCard(controller),
              const SizedBox(height: 16),
              // 汇总卡片
              _buildSummaryCards(controller),
              const SizedBox(height: 24),
              // 趋势图表
              _buildTrendChart(controller),
              const SizedBox(height: 24),
              // 分类统计
              _buildTypeChart(controller),
            ],
          ),
        ),
      );
    });
  }

  /// 构建总收支汇总卡片（所有账本或选中账本）- 紧凑布局
  Widget _buildTotalSummaryCard(ChartsController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D3E50),
            const Color(0xFF2D3E50).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧标题和净收支
          Expanded(
            flex: 2,
            child: _buildTotalSummaryLeftColumn(controller),
          ),
          // 分隔线
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          // 右侧总支出和总收入
          Expanded(
            flex: 3,
            child: _buildTotalSummaryRightColumn(controller),
          ),
        ],
      ),
    );
  }

  /// 构建总汇总卡片左侧列（响应式）
  Widget _buildTotalSummaryLeftColumn(ChartsController controller) {
    return Obx(() {
      final isAllActivities = controller.selectedActivity.value == null;
      final totalExpense = controller.getTotalExpense();
      final totalIncome = controller.getTotalIncome();
      final balance = totalIncome - totalExpense;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isAllActivities ? '所有账本' : '当前账本',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '净收支',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${balance >= 0 ? '+' : ''}¥${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
        ],
      );
    });
  }

  /// 构建总汇总卡片右侧列（响应式）
  Widget _buildTotalSummaryRightColumn(ChartsController controller) {
    return Obx(() {
      final totalExpense = controller.getTotalExpense();
      final totalIncome = controller.getTotalIncome();

      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '总支出',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '¥${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '总收入',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '¥${totalIncome.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  /// 构建汇总卡片（包含当期收支和平均值）
  Widget _buildSummaryCards(ChartsController controller) {
    return Column(
      children: [
        // 第一行：当期支出和收入
        Row(
          children: [
            Expanded(
              child: _buildSummaryCardWidget(
                controller,
                true, // isExpense
                Colors.red,
                Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCardWidget(
                controller,
                false, // isIncome
                Colors.green,
                Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 第二行：平均支出和收入
        Row(
          children: [
            Expanded(
              child: _buildAverageCardWidget(
                controller,
                true, // isExpense
                Colors.orange,
                Icons.trending_down,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAverageCardWidget(
                controller,
                false, // isIncome
                Colors.teal,
                Icons.trending_up,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建汇总卡片（响应式）
  Widget _buildSummaryCardWidget(
    ChartsController controller,
    bool isExpense,
    Color color,
    IconData icon,
  ) {
    return Obx(() {
      final timeDesc = controller.getSelectedTimeDescription();
      final title = isExpense ? '$timeDesc支出' : '$timeDesc收入';
      final value = isExpense
          ? '¥${controller.getCurrentPeriodExpense().toStringAsFixed(2)}'
          : '¥${controller.getCurrentPeriodIncome().toStringAsFixed(2)}';

      return _buildSummaryCard(title, value, color, icon);
    });
  }

  /// 构建平均卡片（响应式）
  Widget _buildAverageCardWidget(
    ChartsController controller,
    bool isExpense,
    Color color,
    IconData icon,
  ) {
    return Obx(() {
      final title = isExpense ? '日均支出' : '日均收入';
      final value = isExpense
          ? '¥${controller.getAverageExpense().toStringAsFixed(2)}'
          : '¥${controller.getAverageIncome().toStringAsFixed(2)}';

      return _buildAverageCard(title, value, controller.getProgressText(), color, icon);
    });
  }

  /// 构建汇总卡片
  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建平均卡片
  Widget _buildAverageCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建趋势图表
  Widget _buildTrendChart(ChartsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTrendChartTitle(controller),
              // 图表显示模式切换按钮
              _buildChartModeSwitcher(controller),
            ],
          ),
          const SizedBox(height: 12),
          // 图例（根据显示模式动态显示）
          _buildChartLegend(controller),
          const SizedBox(height: 20),
          _buildLineChart(
            controller.periodExpenses,
            controller.periodIncome,
            controller,
          ),
        ],
      ),
    );
  }

  /// 构建趋势图表标题（带响应式更新）
  Widget _buildTrendChartTitle(ChartsController controller) {
    return Obx(() {
      final timeDesc = controller.getSelectedTimeDescription();
      return Text(
        '$timeDesc收支趋势',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
    });
  }

  /// 构建图表显示模式切换按钮
  Widget _buildChartModeSwitcher(ChartsController controller) {
    return Obx(() {
      final mode = controller.chartDisplayMode.value;
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeButton('支出', 'expense', mode, controller, Colors.red),
            _buildModeButton('收入', 'income', mode, controller, Colors.green),
            _buildModeButton('两者', 'both', mode, controller, const Color(0xFF2D3E50)),
          ],
        ),
      );
    });
  }

  /// 构建模式切换按钮
  Widget _buildModeButton(String label, String value, String currentMode,
      ChartsController controller, Color activeColor) {
    final isActive = currentMode == value;
    return GestureDetector(
      onTap: () => controller.setChartDisplayMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建图表图例（根据显示模式动态显示）
  Widget _buildChartLegend(ChartsController controller) {
    return Obx(() {
      final mode = controller.chartDisplayMode.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mode == 'expense' || mode == 'both')
            _buildLegendItem('支出', Colors.red),
          if (mode == 'both') const SizedBox(width: 16),
          if (mode == 'income' || mode == 'both')
            _buildLegendItem('收入', Colors.green),
        ],
      );
    });
  }

  /// 构建图例项
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建折线图（根据显示模式显示支出和/或收入）
  Widget _buildLineChart(List<MapEntry<String, double>> expenses, List<MapEntry<String, double>> income, ChartsController controller) {
    if (expenses.isEmpty && income.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return Obx(() {
      final displayMode = controller.chartDisplayMode.value;

      // 根据显示模式决定使用哪些数据
      final List<MapEntry<String, double>> displayExpenses =
          displayMode == 'expense' || displayMode == 'both' ? expenses : [];
      final List<MapEntry<String, double>> displayIncome =
          displayMode == 'income' || displayMode == 'both' ? income : [];

      // 找出最大值
      double maxValue = 0;
      for (var e in displayExpenses) {
        if (e.value > maxValue) maxValue = e.value;
      }
      for (var i in displayIncome) {
        if (i.value > maxValue) maxValue = i.value;
      }
      if (maxValue == 0) maxValue = 1;

      // 直接使用 controller 中已排序的数据顺序，不重新排序
      // 因为字符串排序会导致 "10月" 排在 "2月" 前面
      final List<String> sortedKeys;
      if (displayExpenses.isNotEmpty) {
        sortedKeys = displayExpenses.map((e) => e.key).toList();
      } else if (displayIncome.isNotEmpty) {
        sortedKeys = displayIncome.map((e) => e.key).toList();
      } else {
        sortedKeys = [];
      }

      // 判断是否按月统计（需要间隔显示横坐标）
      final isMonthView = controller.selectedPeriod.value == 'month';
      final interval = isMonthView ? _calculateInterval(sortedKeys.length) : 1;

      return SizedBox(
        height: 240,
        child: Row(
          children: [
            // Y轴标签
            SizedBox(
              width: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('¥${maxValue.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  Text('¥${(maxValue / 2).toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  Text('0', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
                                const SizedBox(width: 8),
                                // 图表区域（带X轴标签）
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final chartWidth = constraints.maxWidth - 48; // 减去左右padding
                                      final double stepX = sortedKeys.length > 1 ? chartWidth / (sortedKeys.length - 1) : 0;            
                            return Column(
                              children: [
                                Expanded(
                                  child: _buildInteractiveChart(
                                    displayExpenses, displayIncome, sortedKeys, maxValue, displayMode,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // X轴标签（与点位对齐）
                                SizedBox(
                                  height: 20,
                                  child: Stack(
                                    children: sortedKeys.asMap().entries
                                      .where((entry) {
                                        final index = entry.key;
                                        // 按月统计时间隔显示
                                        return !isMonthView || (index % interval == 0) || index == sortedKeys.length - 1;
                                      })
                                      .map((entry) {
                                        final index = entry.key;
                                        final key = entry.value;
            
                                        // 计算标签位置，与点位对齐
                                        final double x = 24 + stepX * index; // 24是左侧padding
            
                                        return Positioned(
                                          left: x - 15, // 居中显示，15是半宽
                                          child: SizedBox(
                                            width: 30,
                                            child: Text(
                                              key,
                                              style: TextStyle(
                                                fontSize: isMonthView ? 9 : 10,
                                                color: Colors.grey[500],
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),          ],
        ),
      );
    });
  }

  /// 计算横坐标间隔（根据数据点数量）
  int _calculateInterval(int count) {
    if (count <= 10) return 1; // 10天以内，每天显示
    if (count <= 20) return 2; // 20天以内，每2天显示
    if (count <= 31) return 3; // 31天以内，每3天显示
    return 5;
  }

  /// 构建带悬停交互的图表
  Widget _buildInteractiveChart(
    List<MapEntry<String, double>> expenses,
    List<MapEntry<String, double>> income,
    List<String> sortedKeys,
    double maxValue,
    String displayMode,
  ) {
    return _InteractiveLineChart(
      expenses: expenses,
      income: income,
      sortedKeys: sortedKeys,
      maxValue: maxValue,
      displayMode: displayMode,
    );
  }

  /// 构建分类图表
  Widget _buildTypeChart(ChartsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '分类统计',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // 分类显示模式切换按钮
              _buildTypeModeSwitcher(controller),
            ],
          ),
          const SizedBox(height: 20),
          _buildTypeList(controller),
        ],
      ),
    );
  }

  /// 构建分类显示模式切换按钮
  Widget _buildTypeModeSwitcher(ChartsController controller) {
    return Obx(() {
      final mode = controller.typeDisplayMode.value;
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeModeButton('支出', 'expense', mode, controller, Colors.red),
            _buildTypeModeButton('收入', 'income', mode, controller, Colors.green),
          ],
        ),
      );
    });
  }

  /// 构建分类模式切换按钮
  Widget _buildTypeModeButton(String label, String value, String currentMode,
      ChartsController controller, Color activeColor) {
    final isActive = currentMode == value;
    return GestureDetector(
      onTap: () => controller.setTypeDisplayMode(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建分类列表
  Widget _buildTypeList(ChartsController controller) {
    return Obx(() {
      final data = controller.typeExpenses;
      final isExpenseMode = controller.typeDisplayMode.value == 'expense';
      final barColor = isExpenseMode ? Colors.red : Colors.green;

      if (data.isEmpty) {
        return SizedBox(
          height: 100,
          child: Center(
            child: Text(
              '暂无分类数据',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        );
      }

      final total = data.fold<double>(0, (sum, item) => sum + item.value);
      final sortedData = data.toList()..sort((a, b) => b.value.compareTo(a.value));

      return Column(
        children: sortedData.take(8).map((item) {
          final percentage = total > 0 ? (item.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¥${item.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  /// 显示账本选择器
  void _showActivitySelector(ChartsController controller) {
    final activities = controller.activityService.myActivities.toList()
      ..addAll(controller.activityService.joinedActivities);

    Get.dialog(
      AlertDialog(
        title: const Text('选择账本'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activities.length + 1, // +1 for "所有账本"
            itemBuilder: (context, index) {
              if (index == 0) {
                // 所有账本选项
                final isSelected = controller.selectedActivity.value == null;
                return ListTile(
                  leading: Icon(
                    Icons.folder_copy,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  title: const Text('所有账本'),
                  subtitle: const Text('查看全部账本统计'),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                      : null,
                  selected: isSelected,
                  onTap: () {
                    controller.selectActivity(null);
                    Get.back();
                  },
                );
              }

              final activity = activities[index - 1];
              final isSelected = controller.selectedActivity.value?.activityId == activity.activityId;
              return ListTile(
                leading: Icon(
                  Icons.folder,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                ),
                title: Text(activity.activityName),
                subtitle: Text('创建者: ${activity.creatorName}'),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                selected: isSelected,
                onTap: () {
                  controller.selectActivity(activity);
                  Get.back();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 折线图画布绘制器
class LineChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> expenses;
  final List<MapEntry<String, double>> income;
  final List<String> sortedKeys;
  final double maxValue;
  final String displayMode; // 'expense', 'income', 'both'
  final int? hoveredIndex; // 当前悬停的索引
  final double dotScale; // 点的缩放动画值

  LineChartPainter({
    required this.expenses,
    required this.income,
    required this.sortedKeys,
    required this.maxValue,
    this.displayMode = 'both',
    this.hoveredIndex,
    this.dotScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final double padding = 20;
    final double chartHeight = size.height - padding * 2;
    final double chartWidth = size.width - padding * 2;
    final double stepX = sortedKeys.isNotEmpty ? chartWidth / (sortedKeys.length - 1) : 0;

    // 绘制网格线
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + chartHeight * i / 4;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // 根据显示模式绘制折线
    if (displayMode == 'expense' || displayMode == 'both') {
      _drawLine(canvas, expenses, Colors.red, paint, dotPaint, textPainter,
          chartHeight, chartWidth, stepX, padding, size.height);
    }
    if (displayMode == 'income' || displayMode == 'both') {
      _drawLine(canvas, income, Colors.green, paint, dotPaint, textPainter,
          chartHeight, chartWidth, stepX, padding, size.height);
    }
  }

  void _drawLine(Canvas canvas, List<MapEntry<String, double>> data, Color color,
      Paint paint, Paint dotPaint, TextPainter textPainter,
      double chartHeight, double chartWidth, double stepX, double padding, double canvasHeight) {
    
    paint.color = color;
    dotPaint.color = color;

    final path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final value = data
          .firstWhere((e) => e.key == key, orElse: () => MapEntry(key, 0))
          .value;
      
      final x = padding + stepX * i;
      final y = canvasHeight - padding - (value / maxValue * chartHeight);
      
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 绘制折线
    canvas.drawPath(path, paint);

    // 绘制数据点
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final key = sortedKeys[i];
      final value = data
          .firstWhere((e) => e.key == key, orElse: () => MapEntry(key, 0))
          .value;

      final isHovered = hoveredIndex == i;
      final scale = isHovered ? dotScale : 1.0;

      // 有数据时绘制大点，无数据时绘制小灰点
      if (value > 0) {
        // 如果是悬停状态，绘制外发光效果
        if (isHovered) {
          final glowPaint = Paint()
            ..color = color.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(point, 8 * scale, glowPaint);
        }

        // 绘制主点
        canvas.drawCircle(point, 4 * scale, dotPaint);

        // 绘制白色内圆（空心效果）
        final innerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 2 * scale, innerPaint);
      } else {
        // 无数据时绘制更明显的小灰点（增大尺寸和对比度）
        final emptyDotPaint = Paint()
          ..color = isHovered ? Colors.grey.withValues(alpha: 0.8) : Colors.grey.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 3.5 * scale, emptyDotPaint);
        
        // 绘制白色边框
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(point, 3.5 * scale, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.dotScale != dotScale ||
        oldDelegate.displayMode != displayMode;
  }
}

/// Tooltip 箭头绘制器
class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3D3D3D)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 带悬停交互的折线图组件
class _InteractiveLineChart extends StatefulWidget {
  final List<MapEntry<String, double>> expenses;
  final List<MapEntry<String, double>> income;
  final List<String> sortedKeys;
  final double maxValue;
  final String displayMode;

  const _InteractiveLineChart({
    required this.expenses,
    required this.income,
    required this.sortedKeys,
    required this.maxValue,
    required this.displayMode,
  });

  @override
  State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<_InteractiveLineChart>
    with SingleTickerProviderStateMixin {
  int? hoveredIndex;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = 20.0;
        final chartHeight = constraints.maxHeight - padding * 2;
        final chartWidth = constraints.maxWidth - padding * 2;
        final stepX = widget.sortedKeys.isNotEmpty
            ? chartWidth / (widget.sortedKeys.length - 1).toDouble()
            : 0.0;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return MouseRegion(
              onHover: (event) {
                final localPosition = event.localPosition;
                int? newHoveredIndex;
                double minDistance = double.infinity;

                for (int i = 0; i < widget.sortedKeys.length; i++) {
                  final x = padding + stepX * i;
                  final key = widget.sortedKeys[i];
                  
                  // 检查该索引下的所有可能的点（支出、收入、小灰点）
                  List<double> yPositions = [];
                  
                  // 检查支出点
                  if (widget.displayMode == 'expense' || widget.displayMode == 'both') {
                    final entry = widget.expenses.firstWhere(
                      (e) => e.key == key, orElse: () => MapEntry(key, 0.0));
                    if (entry.value > 0) {
                      final y = constraints.maxHeight - padding - (entry.value / widget.maxValue * chartHeight);
                      yPositions.add(y);
                    }
                  }
                  
                  // 检查收入点
                  if (widget.displayMode == 'income' || widget.displayMode == 'both') {
                    final entry = widget.income.firstWhere(
                      (e) => e.key == key, orElse: () => MapEntry(key, 0.0));
                    if (entry.value > 0) {
                      final y = constraints.maxHeight - padding - (entry.value / widget.maxValue * chartHeight);
                      yPositions.add(y);
                    }
                  }
                  
                  // 始终添加小灰点位置（在底部原点）
                  // 这样即使某天有收入或支出，另一个在原点的小灰点也能被悬停
                  yPositions.add(constraints.maxHeight - padding);
                  
                  // 找到最近的点
                  for (final y in yPositions) {
                    final distance = (localPosition - Offset(x, y)).distance;
                    if (distance < minDistance && distance < 12) {
                      minDistance = distance;
                      newHoveredIndex = i;
                    }
                  }
                }

                if (newHoveredIndex != hoveredIndex) {
                  setState(() {
                    hoveredIndex = newHoveredIndex;
                  });
                  if (newHoveredIndex != null) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                }
              },
              onExit: (_) {
                if (hoveredIndex != null) {
                  setState(() => hoveredIndex = null);
                  _animationController.reverse();
                }
              },
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: LineChartPainter(
                      expenses: widget.expenses,
                      income: widget.income,
                      sortedKeys: widget.sortedKeys,
                      maxValue: widget.maxValue,
                      displayMode: widget.displayMode,
                      hoveredIndex: hoveredIndex,
                      dotScale: _scaleAnimation.value,
                    ),
                  ),
                                  if (hoveredIndex != null)
                                    _buildTooltipAtPoint(hoveredIndex!, stepX, padding, chartHeight, constraints.maxHeight, chartWidth),                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTooltipAtPoint(int index, double stepX, double padding, double chartHeight, double canvasHeight, double chartWidth) {
    final key = widget.sortedKeys[index];

    // 获取该点的数据
    double expenseValue = 0;
    double incomeValue = 0;

    if (widget.displayMode == 'expense' || widget.displayMode == 'both') {
      final expenseEntry = widget.expenses.firstWhere(
        (e) => e.key == key,
        orElse: () => MapEntry(key, 0),
      );
      expenseValue = expenseEntry.value;
    }
    if (widget.displayMode == 'income' || widget.displayMode == 'both') {
      final incomeEntry = widget.income.firstWhere(
        (e) => e.key == key,
        orElse: () => MapEntry(key, 0),
      );
      incomeValue = incomeEntry.value;
    }

    final hasData = expenseValue > 0 || incomeValue > 0;
    final x = padding + stepX * index;
    
    // 计算点的Y坐标（使用有值的那个）
    double value = expenseValue > 0 ? expenseValue : incomeValue;
    final y = canvasHeight - padding - (value / widget.maxValue * chartHeight);

    // 计算 tooltip 位置（在点的上方）
    double tooltipLeft = x - 70;
    double tooltipTop = y - 75;
    
    // 边界检查 - 使用 chartWidth 动态计算
    const tooltipWidth = 140.0;
    if (tooltipLeft < 5) tooltipLeft = 5;
    if (tooltipLeft + tooltipWidth > padding + chartWidth + padding) {
      tooltipLeft = padding + chartWidth + padding - tooltipWidth - 5;
    }
    if (tooltipTop < 5) tooltipTop = y + 15; // 如果上方空间不够，显示在下方

    return Stack(
      children: [
        // Tooltip（跟随点）
        Positioned(
          left: tooltipLeft,
          top: tooltipTop,
          child: AnimatedOpacity(
            opacity: hoveredIndex != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 140,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3D3D3D),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 日期
                  Text(
                    key,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (hasData) ...[
                    if (widget.displayMode == 'expense' || widget.displayMode == 'both') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '支出: ¥${expenseValue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.displayMode == 'income' || widget.displayMode == 'both') ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '收入: ¥${incomeValue.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else
                    const Text(
                      '没有费用',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
