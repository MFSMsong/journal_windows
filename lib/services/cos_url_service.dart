import 'package:get/get.dart';
import 'package:journal_windows/services/tencent_service.dart';

class CosUrlService extends GetxService {
  static CosUrlService get to => Get.find();

  static void init() {
    Get.put(CosUrlService());
  }

  final Map<String, String> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheDuration = Duration(minutes: 25);

  Future<String?> getSignedUrl(String cosPath) async {
    if (cosPath.isEmpty) return null;

    if (cosPath.startsWith('http://') || cosPath.startsWith('https://')) {
      return cosPath;
    }

    final cached = _cache[cosPath];
    final cachedTime = _cacheTime[cosPath];
    if (cached != null && cachedTime != null) {
      if (DateTime.now().difference(cachedTime) < _cacheDuration) {
        return cached;
      }
      _cache.remove(cosPath);
      _cacheTime.remove(cosPath);
    }

    final url = await TencentService.to.getPresignedUrl(cosPath);
    if (url != null) {
      _cache[cosPath] = url;
      _cacheTime[cosPath] = DateTime.now();
    }
    return url;
  }

  String? getCachedUrl(String cosPath) {
    if (cosPath.isEmpty) return null;
    if (cosPath.startsWith('http://') || cosPath.startsWith('https://')) {
      return cosPath;
    }
    return _cache[cosPath];
  }

  bool isCosPath(String? url) {
    if (url == null || url.isEmpty) return false;
    return !url.startsWith('http://') && !url.startsWith('https://');
  }

  void invalidate(String cosPath) {
    _cache.remove(cosPath);
    _cacheTime.remove(cosPath);
  }

  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}
