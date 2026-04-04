import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/asset.dart';
import 'package:journal_windows/services/asset_service.dart';
import 'package:journal_windows/pages/asset/add_asset_dialog.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:intl/intl.dart';

class AssetDetailPage extends StatefulWidget {
  final String assetId;

  const AssetDetailPage({super.key, required this.assetId});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  final AssetService _assetService = AssetService.to;
  Asset? _asset;
  List<AssetRecord> _records = [];
  bool _isLoading = true;
  bool _isAdjusting = false;
  final _adjustController = TextEditingController();
  final _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _adjustController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _asset = _assetService.assets.firstWhereOrNull((a) => a.assetId == widget.assetId);
      if (_asset == null) {
        await _assetService.getAssetList();
        _asset = _assetService.assets.firstWhereOrNull((a) => a.assetId == widget.assetId);
      }
      if (_asset != null) {
        _records = await _assetService.getAssetRecords(widget.assetId);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_asset?.displayName ?? '资产详情'),
        actions: [
          if (_asset != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editAsset,
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除资产', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _asset == null
              ? const Center(child: Text('资产不存在'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 16),
          _buildAdjustButton(),
          const SizedBox(height: 24),
          _buildRecordsSection(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final formatter = NumberFormat('#,##0.00');
    final balanceColor = _asset!.isLiability
        ? (_asset!.balance > 0 ? Colors.red : Colors.green)
        : (_asset!.balance >= 0 ? Colors.green : Colors.red);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(_asset!.assetType),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _asset!.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Asset.getTypeName(_asset!.assetType),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _asset!.isLiability ? '欠款金额' : '当前余额',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥ ${formatter.format(_asset!.balance)}',
            style: TextStyle(
              color: balanceColor.withOpacity(0.9),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_asset!.remark != null && _asset!.remark!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _asset!.remark!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showAdjustDialog,
        icon: const Icon(Icons.edit),
        label: const Text('调整余额'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildRecordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '变动记录',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_records.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('暂无变动记录'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              return _buildRecordItem(_records[index]);
            },
          ),
      ],
    );
  }

  Widget _buildRecordItem(AssetRecord record) {
    final formatter = NumberFormat('#,##0.00');
    final dateTime = DateTime.tryParse(record.createTime);
    final dateStr = dateTime != null
        ? DateFormat('MM-dd HH:mm').format(dateTime)
        : record.createTime;

    final isPositive = record.changeAmount >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    AssetRecord.getOperationName(record.operationType),
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '变动前: ¥ ${formatter.format(record.beforeBalance)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '变动后: ¥ ${formatter.format(record.afterBalance)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isPositive ? "+" : ""}${formatter.format(record.changeAmount)}',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (record.remark != null && record.remark!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.remark!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
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

  void _editAsset() async {
    final result = await Get.dialog(AddAssetDialog(asset: _asset));
    if (result == true) {
      await _loadData();
    }
  }

  void _handleMenuAction(String action) {
    if (action == 'delete') {
      _showDeleteConfirm();
    }
  }

  void _showDeleteConfirm() {
    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${_asset!.displayName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final success = await _assetService.deleteAsset(_asset!.assetId);
              if (success) {
                ToastUtil.showSuccess('资产已删除');
                Get.back(result: true);
              } else {
                ToastUtil.showError('删除失败');
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog() {
    _adjustController.text = _asset!.balance.toString();
    _remarkController.clear();

    Get.dialog(
      AlertDialog(
        title: const Text('调整余额'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _adjustController,
              decoration: const InputDecoration(
                labelText: '新余额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _isAdjusting
                ? null
                : () async {
                    final newBalance = double.tryParse(_adjustController.text);
                    if (newBalance == null) {
                      ToastUtil.showError('请输入有效金额');
                      return;
                    }

                    if (mounted) {
                      setState(() => _isAdjusting = true);
                    }
                    try {
                      final success = await _assetService.adjustBalance(
                        _asset!.assetId,
                        newBalance,
                        remark: _remarkController.text.isEmpty ? null : _remarkController.text,
                      );
                      if (success) {
                        Get.back();
                        ToastUtil.showSuccess('余额已调整');
                        await _loadData();
                      } else {
                        ToastUtil.showError('调整失败');
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isAdjusting = false);
                      }
                    }
                  },
            child: _isAdjusting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('确认'),
          ),
        ],
      ),
    );
  }
}
