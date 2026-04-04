import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/asset.dart';
import 'package:journal_windows/services/asset_service.dart';
import 'package:journal_windows/utils/toast_util.dart';

class AddAssetDialog extends StatefulWidget {
  final Asset? asset;

  const AddAssetDialog({super.key, this.asset});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _cardLastFourController = TextEditingController();
  final _balanceController = TextEditingController();
  final _remarkController = TextEditingController();

  int _selectedType = Asset.TYPE_CASH;
  bool _isLoading = false;
  bool get isEdit => widget.asset != null;

  final List<Map<String, dynamic>> _assetTypes = [
    {'type': Asset.TYPE_CASH, 'name': '现金', 'icon': Icons.payments, 'color': Colors.green},
    {'type': Asset.TYPE_SAVINGS_CARD, 'name': '储蓄卡', 'icon': Icons.account_balance, 'color': Colors.blue},
    {'type': Asset.TYPE_CREDIT_CARD, 'name': '信用卡', 'icon': Icons.credit_card, 'color': Colors.purple},
    {'type': Asset.TYPE_VIRTUAL, 'name': '虚拟账户', 'icon': Icons.phone_android, 'color': Colors.orange},
    {'type': Asset.TYPE_INVESTMENT, 'name': '投资账户', 'icon': Icons.trending_up, 'color': Colors.teal},
    {'type': Asset.TYPE_DEBT, 'name': '负债', 'icon': Icons.money_off, 'color': Colors.red},
    {'type': Asset.TYPE_RECEIVABLE, 'name': '债权', 'icon': Icons.receipt_long, 'color': Colors.indigo},
    {'type': Asset.TYPE_CUSTOM, 'name': '自定义', 'icon': Icons.account_balance_wallet, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.asset != null) {
      _selectedType = widget.asset!.assetType;
      _nameController.text = widget.asset!.name;
      _bankNameController.text = widget.asset!.bankName ?? '';
      _cardLastFourController.text = widget.asset!.cardLastFour ?? '';
      _balanceController.text = widget.asset!.balance.toString();
      _remarkController.text = widget.asset!.remark ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _cardLastFourController.dispose();
    _balanceController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  bool get _needBankInfo =>
      _selectedType == Asset.TYPE_SAVINGS_CARD || _selectedType == Asset.TYPE_CREDIT_CARD;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 16),
                      _buildNameField(),
                      if (_needBankInfo) ...[
                        const SizedBox(height: 12),
                        _buildBankNameField(),
                        const SizedBox(height: 12),
                        _buildCardLastFourField(),
                      ],
                      const SizedBox(height: 12),
                      _buildBalanceField(),
                      const SizedBox(height: 12),
                      _buildRemarkField(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(
            isEdit ? Icons.edit : Icons.add,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            isEdit ? '编辑资产' : '添加资产',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '资产类型',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _assetTypes.map((item) {
            final isSelected = _selectedType == item['type'];
            return InkWell(
              onTap: () => setState(() => _selectedType = item['type']),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? (item['color'] as Color).withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? (item['color'] as Color) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: isSelected ? (item['color'] as Color) : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['name'] as String,
                      style: TextStyle(
                        color: isSelected ? (item['color'] as Color) : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: _needBankInfo ? '账户名称（可选）' : '资产名称',
        hintText: _needBankInfo ? '例如：工资卡' : '例如：钱包现金',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: _needBankInfo
          ? null
          : (value) {
              if (value == null || value.isEmpty) {
                return '请输入资产名称';
              }
              return null;
            },
    );
  }

  Widget _buildBankNameField() {
    return TextFormField(
      controller: _bankNameController,
      decoration: InputDecoration(
        labelText: '银行名称',
        hintText: '例如：招商银行',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: (value) {
        if (_needBankInfo && (value == null || value.isEmpty)) {
          return '请输入银行名称';
        }
        return null;
      },
    );
  }

  Widget _buildCardLastFourField() {
    return TextFormField(
      controller: _cardLastFourController,
      decoration: InputDecoration(
        labelText: '卡号后四位',
        hintText: '例如：8888',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: TextInputType.number,
      maxLength: 4,
      validator: (value) {
        if (_needBankInfo && (value == null || value.isEmpty)) {
          return '请输入卡号后四位';
        }
        if (value != null && value.isNotEmpty && value.length != 4) {
          return '请输入4位数字';
        }
        return null;
      },
    );
  }

  Widget _buildBalanceField() {
    return TextFormField(
      controller: _balanceController,
      decoration: InputDecoration(
        labelText: '当前余额',
        hintText: '0.00',
        prefixText: '¥ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入余额';
        }
        if (double.tryParse(value) == null) {
          return '请输入有效数字';
        }
        return null;
      },
    );
  }

  Widget _buildRemarkField() {
    return TextFormField(
      controller: _remarkController,
      decoration: InputDecoration(
        labelText: '备注（可选）',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      maxLines: 2,
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final asset = Asset(
        assetId: widget.asset?.assetId ?? '',
        userId: '',
        assetType: _selectedType,
        name: _needBankInfo
            ? (_nameController.text.isEmpty ? _bankNameController.text : _nameController.text)
            : _nameController.text,
        bankName: _needBankInfo ? _bankNameController.text : null,
        cardLastFour: _needBankInfo ? _cardLastFourController.text : null,
        balance: double.parse(_balanceController.text),
        remark: _remarkController.text.isEmpty ? null : _remarkController.text,
        createTime: widget.asset?.createTime ?? '',
      );

      final assetService = AssetService.to;
      bool success;
      if (isEdit) {
        success = await assetService.updateAsset(asset);
      } else {
        final newAsset = await assetService.createAsset(asset);
        success = newAsset != null;
      }

      if (!mounted) return;

      if (success) {
        Get.back(result: true);
        ToastUtil.showSuccess(isEdit ? '资产已更新' : '资产已添加');
      } else {
        setState(() => _isLoading = false);
        ToastUtil.showError(isEdit ? '更新失败，请检查网络连接' : '添加失败，请检查网络连接');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ToastUtil.showError('操作失败: $e');
    }
  }
}
