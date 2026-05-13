import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/asset.dart';
import 'package:journal_windows/services/asset_service.dart';

class AssetChartsController extends GetxController {
  final AssetService assetService = AssetService.to;

  final selectedTab = 'asset'.obs;
  final selectedYear = DateTime.now().year.obs;

  final trendData = <MapEntry<String, double>>[].obs;
  final distributionData = <AssetDistributionItem>[].obs;
  final isLoadingTrend = false.obs;

  static const int typeCash = 1;
  static const int typeSavingsCard = 2;
  static const int typeCreditCard = 3;
  static const int typeVirtual = 4;
  static const int typeInvestment = 5;
  static const int typeDebt = 6;
  static const int typeReceivable = 7;
  static const int typeCustom = 8;

  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
    ever(assetService.assets, (_) => _calculateDistribution());
    ever(assetService.overview, (_) => _calculateDistribution());
  }

  Future<void> loadData() async {
    await assetService.refresh();
    _calculateDistribution();
    await _loadTrendData();
  }

  void _calculateDistribution() {
    final List<AssetDistributionItem> items = [];
    final filteredAssets = _getFilteredAssets();

    final typeMap = <int, double>{};
    for (final asset in filteredAssets) {
      typeMap[asset.assetType] = (typeMap[asset.assetType] ?? 0) + asset.balance.abs();
    }

    for (final entry in typeMap.entries) {
      items.add(AssetDistributionItem(
        type: entry.key,
        typeName: getTypeName(entry.key),
        amount: entry.value,
        color: getTypeColor(entry.key),
      ));
    }

    items.sort((a, b) => b.amount.compareTo(a.amount));
    distributionData.value = items;
  }

  List<Asset> _getFilteredAssets() {
    switch (selectedTab.value) {
      case 'asset':
        return assetService.assets.where((a) => !a.isLiability).toList();
      case 'liability':
        return assetService.assets.where((a) => a.isLiability).toList();
      case 'netAsset':
        return assetService.assets;
      default:
        return assetService.assets;
    }
  }

  double _getTotalValue() {
    switch (selectedTab.value) {
      case 'asset':
        return assetService.overview.value?.totalAsset ?? 0;
      case 'liability':
        return assetService.overview.value?.totalLiability ?? 0;
      case 'netAsset':
        return assetService.overview.value?.netAsset ?? 0;
      default:
        return 0;
    }
  }

  Future<void> _loadTrendData() async {
    isLoadingTrend.value = true;
    try {
      final data = await assetService.getYearlyTrend(selectedYear.value, selectedTab.value);
      trendData.value = data;
    } finally {
      isLoadingTrend.value = false;
    }
  }

  void setTab(String tab) {
    if (selectedTab.value != tab) {
      selectedTab.value = tab;
      _calculateDistribution();
      _loadTrendData();
    }
  }

  void setYear(int year) {
    if (selectedYear.value != year) {
      selectedYear.value = year;
      _loadTrendData();
    }
  }

  String getTypeName(int type) {
    switch (type) {
      case typeCash:
        return '现金';
      case typeSavingsCard:
        return '储蓄卡';
      case typeCreditCard:
        return '信用卡';
      case typeVirtual:
        return '虚拟账户';
      case typeInvestment:
        return '投资账户';
      case typeDebt:
        return '负债';
      case typeReceivable:
        return '债权';
      case typeCustom:
        return '自定义';
      default:
        return '其他';
    }
  }

  Color getTypeColor(int type) {
    switch (type) {
      case typeCash:
        return const Color(0xFF4CAF50);
      case typeSavingsCard:
        return const Color(0xFFFF9800);
      case typeCreditCard:
        return const Color(0xFFE91E63);
      case typeVirtual:
        return const Color(0xFF2196F3);
      case typeInvestment:
        return const Color(0xFF9C27B0);
      case typeDebt:
        return const Color(0xFFF44336);
      case typeReceivable:
        return const Color(0xFF00BCD4);
      case typeCustom:
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  List<AssetRankingItem> getRankingList() {
    final filteredAssets = _getFilteredAssets();
    final total = _getTotalValue();

    final items = filteredAssets.map((asset) {
      final percentage = total != 0 ? (asset.balance.abs() / total.abs() * 100) : 0.0;
      return AssetRankingItem(
        asset: asset,
        percentage: percentage,
      );
    }).toList();

    items.sort((a, b) => b.asset.balance.abs().compareTo(a.asset.balance.abs()));
    return items;
  }
}

class AssetDistributionItem {
  final int type;
  final String typeName;
  final double amount;
  final Color color;

  AssetDistributionItem({
    required this.type,
    required this.typeName,
    required this.amount,
    required this.color,
  });
}

class AssetRankingItem {
  final Asset asset;
  final double percentage;

  AssetRankingItem({
    required this.asset,
    required this.percentage,
  });
}
