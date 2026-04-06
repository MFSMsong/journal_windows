import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/asset.dart';
import 'package:journal_windows/pages/asset/asset_list_controller.dart';
import 'package:journal_windows/pages/asset/asset_detail_page.dart';
import 'package:journal_windows/pages/asset/add_asset_dialog.dart';
import 'package:journal_windows/pages/asset/asset_charts_page.dart';
import 'package:intl/intl.dart';

class AssetListPage extends StatefulWidget {
  const AssetListPage({super.key});

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AssetListController());

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, controller),
          Expanded(child: _buildBody(controller)),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Get.dialog(const AddAssetDialog());
                if (result == true) {
                  await controller.refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('添加资产'),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AssetListController controller) {
    final title = _currentIndex == 0 ? '资产管理' : '资产图表';
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: '刷新',
            onPressed: () => controller.refresh(),
          ),
          const Spacer(),
          _buildTabButtons(),
        ],
      ),
    );
  }

  Widget _buildTabButtons() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabButton('资产列表', 0),
          _buildTabButton('资产图表', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AssetListController controller) {
    if (_currentIndex == 1) {
      return const AssetChartsPage();
    }
    return _buildContent(context, controller);
  }

  Widget _buildContent(BuildContext context, AssetListController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.assets.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(context, controller),
            const SizedBox(height: 16),
            _buildAssetSection(context, controller, '资产账户', controller.assetList, false),
            const SizedBox(height: 16),
            _buildAssetSection(context, controller, '负债账户', controller.liabilityList, true),
          ],
        ),
      );
    });
  }

  Widget _buildOverviewCard(BuildContext context, AssetListController controller) {
    final overview = controller.overview;
    final formatter = NumberFormat('#,##0.00');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '净资产',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥ ${formatter.format(overview?.netAsset ?? 0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  '总资产',
                  '¥ ${formatter.format(overview?.totalAsset ?? 0)}',
                  Icons.arrow_upward,
                  Colors.greenAccent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildOverviewItem(
                  '总负债',
                  '¥ ${formatter.format(overview?.totalLiability ?? 0)}',
                  Icons.arrow_downward,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetSection(
    BuildContext context,
    AssetListController controller,
    String title,
    List<Asset> assetList,
    bool isLiability,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (assetList.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '暂无${isLiability ? '负债' : '资产'}账户',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assetList.length,
            itemBuilder: (context, index) {
              return _buildAssetCard(context, controller, assetList[index]);
            },
          ),
      ],
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    AssetListController controller,
    Asset asset,
  ) {
    final formatter = NumberFormat('#,##0.00');
    final balanceColor = asset.isLiability
        ? (asset.balance > 0 ? Colors.red : Colors.green)
        : (asset.balance >= 0 ? Colors.green : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Get.to(() => AssetDetailPage(assetId: asset.assetId));
          await controller.refresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(asset.assetType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(asset.assetType),
                  color: _getTypeColor(asset.assetType),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Asset.getTypeName(asset.assetType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥ ${formatter.format(asset.balance)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  if (asset.remark != null && asset.remark!.isNotEmpty)
                    Text(
                      asset.remark!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(int type) {
    switch (type) {
      case Asset.TYPE_CASH:
        return Icons.payments;
      case Asset.TYPE_SAVINGS_CARD:
        return Icons.account_balance;
      case Asset.TYPE_CREDIT_CARD:
        return Icons.credit_card;
      case Asset.TYPE_VIRTUAL:
        return Icons.phone_android;
      case Asset.TYPE_INVESTMENT:
        return Icons.trending_up;
      case Asset.TYPE_DEBT:
        return Icons.money_off;
      case Asset.TYPE_RECEIVABLE:
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case Asset.TYPE_CASH:
        return Colors.green;
      case Asset.TYPE_SAVINGS_CARD:
        return Colors.blue;
      case Asset.TYPE_CREDIT_CARD:
        return Colors.purple;
      case Asset.TYPE_VIRTUAL:
        return Colors.orange;
      case Asset.TYPE_INVESTMENT:
        return Colors.teal;
      case Asset.TYPE_DEBT:
        return Colors.red;
      case Asset.TYPE_RECEIVABLE:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}
