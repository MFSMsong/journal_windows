import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:journal_windows/pages/asset/asset_charts_controller.dart';
import 'package:journal_windows/pages/asset/asset_detail_page.dart';

class AssetChartsPage extends StatelessWidget {
  const AssetChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AssetChartsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildTabSelector(controller),
          Expanded(child: _buildContent(controller)),
        ],
      ),
    );
  }

  Widget _buildTabSelector(AssetChartsController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Obx(() => Row(
        children: [
          _buildTabChip('资产', 'asset', controller, Colors.green),
          const SizedBox(width: 8),
          _buildTabChip('负债', 'liability', controller, Colors.red),
          const SizedBox(width: 8),
          _buildTabChip('净资产', 'netAsset', controller, Colors.blue),
        ],
      )),
    );
  }

  Widget _buildTabChip(String label, String value, AssetChartsController controller, Color color) {
    final isSelected = controller.selectedTab.value == value;
    return GestureDetector(
      onTap: () => controller.setTab(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AssetChartsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.assets.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildOverviewCard(controller),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTrendChart(controller),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                // 净资产页面显示资产状况卡片，其他页面显示饼状图和排行榜
                if (controller.selectedTab.value == 'netAsset') {
                  return _buildNetAssetStatusCard(controller);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildDistributionChart(controller)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildRankingList(controller)),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOverviewCard(AssetChartsController controller) {
    return Obx(() {
      final overview = controller.overview.value;
      final tab = controller.selectedTab.value;

      double displayValue;
      String label;
      Color valueColor;

      switch (tab) {
        case 'asset':
          displayValue = overview?.totalAsset ?? 0;
          label = '总资产';
          valueColor = Colors.green;
          break;
        case 'liability':
          displayValue = overview?.totalLiability ?? 0;
          label = '总负债';
          valueColor = Colors.red;
          break;
        case 'netAsset':
        default:
          displayValue = overview?.netAsset ?? 0;
          label = '净资产';
          valueColor = displayValue >= 0 ? Colors.blue : Colors.red;
      }

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(Get.context!).primaryColor,
              Theme.of(Get.context!).primaryColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${NumberFormat('#,##0.00').format(displayValue)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            if (tab == 'netAsset') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOverviewItem('总资产', overview?.totalAsset ?? 0, Colors.greenAccent),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildOverviewItem('总负债', overview?.totalLiability ?? 0, Colors.redAccent),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildOverviewItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¥${NumberFormat('#,##0.00').format(value)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(AssetChartsController controller) {
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
              Obx(() => Text(
                '${controller.selectedYear.value}年资产走势',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )),
              _buildYearSelector(controller),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() => _buildInteractiveLineChart(controller)),
        ],
      ),
    );
  }

  Widget _buildYearSelector(AssetChartsController controller) {
    return Obx(() {
      final years = controller.availableYears;
      final selectedYear = controller.selectedYear.value;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedYear,
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            borderRadius: BorderRadius.circular(8),
            items: years.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text('$year年'),
              );
            }).toList(),
            onChanged: (year) {
              if (year != null) {
                controller.setYear(year);
              }
            },
          ),
        ),
      );
    });
  }

  Widget _buildInteractiveLineChart(AssetChartsController controller) {
    final data = controller.trendData;
    if (data.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text('暂无数据', style: TextStyle(color: Colors.grey[400])),
        ),
      );
    }

    final tab = controller.selectedTab.value;
    final allValues = data.map((e) => e.value).toList();
    var maxValue = allValues.reduce(math.max);
    var minValue = allValues.reduce(math.min);
    
    // 根据tab类型确定纵坐标范围
    if (tab == 'asset' || tab == 'liability') {
      // 资产和负债：只有正数，从0开始
      minValue = 0;
      if (maxValue <= 0) {
        maxValue = 1000;
      } else {
        maxValue = maxValue * 1.2;
      }
    } else {
      // 净资产：0点在中间位置
      if (maxValue == minValue) {
        if (maxValue == 0) {
          maxValue = 1000;
          minValue = -1000;
        } else if (maxValue > 0) {
          maxValue = maxValue * 1.2;
          minValue = -maxValue;
        } else {
          minValue = minValue * 1.2;
          maxValue = -minValue;
        }
      } else {
        // 让maxValue和minValue对称，0点在中间
        final absMax = math.max(maxValue.abs(), minValue.abs());
        maxValue = absMax * 1.2;
        minValue = -maxValue;
      }
    }
    
    var range = maxValue - minValue;
    if (range == 0) range = 1000;
    final displayMax = maxValue;
    final displayMin = minValue;

    return SizedBox(
      height: 240,
      child: _AssetInteractiveLineChart(
        data: data,
        maxValue: displayMax,
        minValue: displayMin,
        year: controller.selectedYear.value,
      ),
    );
  }

  Widget _buildDistributionChart(AssetChartsController controller) {
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
          const Text(
            '资产分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => _buildPieChart(controller)),
        ],
      ),
    );
  }

  Widget _buildPieChart(AssetChartsController controller) {
    final data = controller.distributionData;
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('暂无数据', style: TextStyle(color: Colors.grey[400])),
        ),
      );
    }

    final total = data.fold<double>(0, (sum, item) => sum + item.amount);

    return Row(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(
            painter: AssetPieChartPainter(
              data: data,
              total: total,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.take(5).map((item) {
              final percentage = total > 0 ? (item.amount / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.typeName,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList(AssetChartsController controller) {
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
          const Text(
            '资产排行',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => _buildRankingItems(controller)),
        ],
      ),
    );
  }

  Widget _buildRankingItems(AssetChartsController controller) {
    final items = controller.getRankingList();

    if (items.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text('暂无数据', style: TextStyle(color: Colors.grey[400])),
        ),
      );
    }

    return Column(
      children: items.take(6).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              await Get.to(() => AssetDetailPage(assetId: item.asset.assetId));
              controller.loadData();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: controller.getTypeColor(item.asset.assetType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(item.asset.assetType),
                      size: 18,
                      color: controller.getTypeColor(item.asset.assetType),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.asset.displayName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: item.percentage / 100,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: controller.getTypeColor(item.asset.assetType),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${NumberFormat('#,##0.00').format(item.asset.balance)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.asset.balance >= 0 ? Colors.black87 : Colors.red,
                        ),
                      ),
                      Text(
                        '${item.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 净资产状况卡片
  Widget _buildNetAssetStatusCard(AssetChartsController controller) {
    return Obx(() {
      final overview = controller.overview.value;
      final totalAsset = overview?.totalAsset ?? 0;
      final totalLiability = overview?.totalLiability ?? 0;
      final netAsset = overview?.netAsset ?? 0;

      // 计算资产负债率
      final debtRatio = totalAsset > 0 ? (totalLiability / totalAsset * 100) : 0.0;

      return Container(
        padding: const EdgeInsets.all(24),
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
            const Text(
              '当前净资产状况',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 24),
            // 资产和负债数值
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(totalAsset),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                Text(
                  NumberFormat('#,##0.00').format(totalLiability),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 资产负债比例进度条
            _buildAssetLiabilityBar(totalAsset, totalLiability),
            const SizedBox(height: 24),
            // 净资产
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '净资产',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  '¥${NumberFormat('#,##0.00').format(netAsset)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: netAsset >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 资产负债率
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '资产负债率',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  '${debtRatio.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: debtRatio > 50 ? const Color(0xFFF44336) : const Color(0xFF222222),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// 资产负债比例进度条
  Widget _buildAssetLiabilityBar(double totalAsset, double totalLiability) {
    final total = totalAsset + totalLiability;
    final assetPercent = total > 0 ? (totalAsset / total) : 1.0;
    final liabilityPercent = total > 0 ? (totalLiability / total) : 0.0;

    return Column(
      children: [
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              // 资产部分（黄色）
              Expanded(
                flex: (assetPercent * 1000).round().clamp(1, 999),
                child: Container(
                  height: 48,
                  color: const Color(0xFFF9D65A),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  child: assetPercent > 0.1
                      ? const Text(
                          '资产',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        )
                      : null,
                ),
              ),
              // 负债部分（深灰）
              if (liabilityPercent > 0)
                Expanded(
                  flex: (liabilityPercent * 1000).round().clamp(1, 999),
                  child: Container(
                    height: 48,
                    color: const Color(0xFF333333),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: liabilityPercent > 0.1
                        ? const Text(
                            '负债',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(int type) {
    switch (type) {
      case 1:
        return Icons.payments_outlined;
      case 2:
        return Icons.credit_card;
      case 3:
        return Icons.credit_card;
      case 4:
        return Icons.account_balance_wallet;
      case 5:
        return Icons.trending_up;
      case 6:
        return Icons.trending_down;
      case 7:
        return Icons.receipt_long;
      default:
        return Icons.account_balance;
    }
  }
}

class _AssetInteractiveLineChart extends StatefulWidget {
  final List<MapEntry<String, double>> data;
  final double maxValue;
  final double minValue;
  final int year;

  const _AssetInteractiveLineChart({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.year,
  });

  @override
  State<_AssetInteractiveLineChart> createState() => _AssetInteractiveLineChartState();
}

class _AssetInteractiveLineChartState extends State<_AssetInteractiveLineChart>
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
        final padding = 24.0;
        final chartHeight = constraints.maxHeight - padding * 2;
        final chartWidth = constraints.maxWidth - padding * 2;
        final stepX = widget.data.isNotEmpty
            ? chartWidth / (widget.data.length - 1).toDouble()
            : 0.0;

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return MouseRegion(
              onHover: (event) {
                final localPosition = event.localPosition;
                int? newHoveredIndex;
                double minDistance = double.infinity;

                for (int i = 0; i < widget.data.length; i++) {
                  final value = widget.data[i].value;
                  
                  final x = padding + stepX * i;
                  final y = constraints.maxHeight - padding -
                      ((value - widget.minValue) / (widget.maxValue - widget.minValue) * chartHeight);

                  final distance = (localPosition - Offset(x, y)).distance;
                  if (distance < minDistance && distance < 15) {
                    minDistance = distance;
                    newHoveredIndex = i;
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
                    painter: AssetLineChartPainter(
                      data: widget.data,
                      maxValue: widget.maxValue,
                      minValue: widget.minValue,
                      color: Theme.of(context).primaryColor,
                      hoveredIndex: hoveredIndex,
                      dotScale: _scaleAnimation.value,
                    ),
                  ),
                  if (hoveredIndex != null)
                    _buildTooltip(hoveredIndex!, stepX, padding, chartHeight, constraints),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTooltip(int index, double stepX, double padding, double chartHeight, BoxConstraints constraints) {
    final item = widget.data[index];
    final x = padding + stepX * index;
    final y = constraints.maxHeight - padding -
        ((item.value - widget.minValue) / (widget.maxValue - widget.minValue) * chartHeight);

    double tooltipLeft = x - 60;
    double tooltipTop = y - 70;

    const tooltipWidth = 120.0;
    if (tooltipLeft < 5) tooltipLeft = 5;
    if (tooltipLeft + tooltipWidth > constraints.maxWidth - 5) {
      tooltipLeft = constraints.maxWidth - tooltipWidth - 5;
    }
    if (tooltipTop < 5) tooltipTop = y + 15;

    final month = index + 1;
    final dateStr = '${widget.year}年${month.toString().padLeft(2, '0')}月';

    return Positioned(
      left: tooltipLeft,
      top: tooltipTop,
      child: AnimatedOpacity(
        opacity: hoveredIndex != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: tooltipWidth,
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
              Text(
                dateStr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¥${NumberFormat('#,##0.00').format(item.value)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetLineChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double maxValue;
  final double minValue;
  final Color color;
  final int? hoveredIndex;
  final double dotScale;

  AssetLineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.color,
    this.hoveredIndex,
    this.dotScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 24.0;
    final chartHeight = size.height - padding * 2;
    final chartWidth = size.width - padding * 2;
    var range = maxValue - minValue;
    if (range == 0) range = 1;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + chartHeight * i / 4;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    final yLabels = [
      _formatValue(maxValue),
      _formatValue((maxValue + minValue) / 2),
      _formatValue(minValue),
    ];

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i < 3; i++) {
      textPainter.text = TextSpan(
        text: '¥${yLabels[i]}',
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(0, padding + chartHeight * i / 2 - textPainter.height / 2),
      );
    }

    final stepX = data.length > 1 ? chartWidth / (data.length - 1) : 0.0;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(padding, padding, chartWidth, chartHeight));

    // 绘制折线路径
    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < data.length; i++) {
      final x = padding + stepX * i;
      final y = size.height - padding - ((data[i].value - minValue) / range * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - padding);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(padding + stepX * (data.length - 1), size.height - padding);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // 绘制所有数据点
    for (int i = 0; i < data.length; i++) {
      final x = padding + stepX * i;
      final y = size.height - padding - ((data[i].value - minValue) / range * chartHeight);
      final isHovered = i == hoveredIndex;
      final radius = isHovered ? 6.0 * dotScale : 4.0;

      final dotPaint = Paint()
        ..color = isHovered ? color : Colors.white
        ..style = PaintingStyle.fill;

      final dotBorderPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(x, y), radius, dotPaint);
      canvas.drawCircle(Offset(x, y), radius, dotBorderPaint);
    }

    // 绘制月份标签
    for (int i = 0; i < data.length; i++) {
      final x = padding + stepX * i;
      textPainter.text = TextSpan(
        text: data[i].key,
        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - padding + 8),
      );
    }
  }

  String _formatValue(double value) {
    if (value.abs() >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant AssetLineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.color != color ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.dotScale != dotScale;
  }
}

class AssetPieChartPainter extends CustomPainter {
  final List<AssetDistributionItem> data;
  final double total;

  AssetPieChartPainter({
    required this.data,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final innerRadius = radius * 0.6;

    double startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = (item.amount / total) * 2 * math.pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: (radius + innerRadius) / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius - 2, centerPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '总计\n¥${_formatTotal(total)}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  String _formatTotal(double value) {
    if (value.abs() >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}万';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant AssetPieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}
