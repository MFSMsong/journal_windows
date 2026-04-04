import 'package:get/get.dart';
import 'package:journal_windows/models/asset.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/core/log.dart';

class AssetService extends GetxService {
  static AssetService get to => Get.find();

  final RxList<Asset> assets = <Asset>[].obs;
  final Rx<AssetOverview?> overview = Rx<AssetOverview?>(null);
  final RxBool isLoading = false.obs;

  Future<AssetOverview?> getOverview() async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getAssetOverview(),
      );
      if (result != null) {
        overview.value = AssetOverview.fromJson(result);
        return overview.value;
      }
    } catch (e) {
      Log().e('获取资产概览失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  Future<List<Asset>> getAssetList() async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getAssetList(),
      );
      if (result != null) {
        assets.value = result.map((e) => Asset.fromJson(e)).toList();
        return assets;
      }
    } catch (e) {
      Log().e('获取资产列表失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  Future<Asset?> createAsset(Asset asset) async {
    isLoading.value = true;
    try {
      Log().d('创建资产: ${asset.toJson()}');
      final result = await HttpRequest.post<Map<String, dynamic>>(
        ApiConfig.createAsset(),
        data: asset.toJson(),
      );
      Log().d('创建资产响应: $result, 类型: ${result.runtimeType}');
      if (result != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(result);
        final newAsset = Asset.fromJson(data);
        assets.add(newAsset);
        await getOverview();
        return newAsset;
      }
    } catch (e) {
      Log().e('创建资产失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  Future<bool> updateAsset(Asset asset) async {
    isLoading.value = true;
    try {
      await HttpRequest.put<Map<String, dynamic>>(
        ApiConfig.updateAsset(asset.assetId),
        data: asset.toJson(),
      );
      final index = assets.indexWhere((a) => a.assetId == asset.assetId);
      if (index != -1) {
        assets[index] = asset;
      }
      await getOverview();
      return true;
    } catch (e) {
      Log().e('更新资产失败: $e');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> deleteAsset(String assetId) async {
    isLoading.value = true;
    try {
      await HttpRequest.delete<Map<String, dynamic>>(
        ApiConfig.deleteAsset(assetId),
      );
      assets.removeWhere((a) => a.assetId == assetId);
      await getOverview();
      return true;
    } catch (e) {
      Log().e('删除资产失败: $e');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> adjustBalance(String assetId, double newBalance, {String? remark}) async {
    isLoading.value = true;
    try {
      await HttpRequest.post<Map<String, dynamic>>(
        ApiConfig.adjustAssetBalance(assetId),
        data: {
          'balance': newBalance,
          'remark': remark,
        },
      );
      return true;
    } catch (e) {
      Log().e('调整余额失败: $e');
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<List<AssetRecord>> getAssetRecords(String assetId) async {
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getAssetRecords(assetId),
      );
      if (result != null) {
        return result.map((e) => AssetRecord.fromJson(e)).toList();
      }
    } catch (e) {
      Log().e('获取资产记录失败: $e');
    }
    return [];
  }

  Future<void> refresh() async {
    await Future.wait([
      getOverview(),
      getAssetList(),
    ]);
  }
}
