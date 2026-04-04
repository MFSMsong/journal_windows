import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/asset.dart';
import 'package:journal_windows/services/asset_service.dart';

class AssetListController extends GetxController {
  final AssetService assetService = AssetService.to;
  
  final RxInt selectedTypeFilter = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
    });
  }

  Future<void> loadData() async {
    await assetService.refresh();
  }

  @override
  Future<void> refresh() async {
    await loadData();
  }

  List<Asset> get assets => assetService.assets;
  
  AssetOverview? get overview => assetService.overview.value;
  
  RxBool get isLoading => assetService.isLoading;

  List<Asset> get filteredAssets {
    if (selectedTypeFilter.value == 0) {
      return assets;
    }
    return assets.where((a) => a.assetType == selectedTypeFilter.value).toList();
  }

  List<Asset> get assetList => assets.where((a) => !a.isLiability).toList();
  
  List<Asset> get liabilityList => assets.where((a) => a.isLiability).toList();

  Future<void> deleteAsset(String assetId) async {
    await assetService.deleteAsset(assetId);
  }
}
