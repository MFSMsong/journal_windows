import 'package:get/get.dart';
import 'package:journal_windows/services/tencent_service.dart';

/// COS URL 签名服务
/// 
/// 负责管理 COS 文件的预签名 URL，包括：
/// 1. 从后端获取预签名下载 URL
/// 2. 本地缓存签名 URL（避免频繁请求后端）
/// 3. 自动处理 URL 过期刷新
/// 
/// 缓存策略：
/// - 签名 URL 有效期：30分钟（后端设置）
/// - 本地缓存时长：25分钟（留5分钟余量，避免使用即将过期的 URL）
/// - 缓存命中时直接返回，不请求后端
/// 
/// 使用场景：
/// - CosImage 组件自动调用获取签名 URL 显示图片
/// - 需要下载文件时获取临时访问链接
class CosUrlService extends GetxService {
  static CosUrlService get to => Get.find();

  static void init() {
    Get.put(CosUrlService());
  }

  /// 签名 URL 缓存
  /// key: COS 路径（如 Image/Avatar/xxx.jpg）
  /// value: 预签名 URL
  final Map<String, String> _cache = {};
  
  /// 缓存时间记录
  /// key: COS 路径
  /// value: 缓存时间（用于判断是否过期）
  final Map<String, DateTime> _cacheTime = {};
  
  /// 缓存有效期
  /// 设置为 25 分钟，比后端签名有效期（30分钟）少 5 分钟
  /// 这样可以避免使用即将过期的 URL
  static const Duration _cacheDuration = Duration(minutes: 25);

  /// 获取签名 URL（带缓存）
  /// 
  /// 工作流程：
  /// 1. 如果已经是完整 URL，直接返回
  /// 2. 检查缓存是否存在且未过期
  /// 3. 缓存命中则直接返回缓存的 URL
  /// 4. 缓存未命中则从后端获取新的签名 URL
  /// 5. 将新 URL 存入缓存并返回
  /// 
  /// [cosPath] COS 路径或完整 URL
  /// 返回: 带签名的访问 URL
  Future<String?> getSignedUrl(String cosPath) async {
    if (cosPath.isEmpty) return null;

    // 如果已经是完整 URL，直接返回（可能是外部链接）
    if (cosPath.startsWith('http://') || cosPath.startsWith('https://')) {
      return cosPath;
    }

    // 检查缓存是否存在
    final cached = _cache[cosPath];
    final cachedTime = _cacheTime[cosPath];
    
    if (cached != null && cachedTime != null) {
      // 检查缓存是否过期
      if (DateTime.now().difference(cachedTime) < _cacheDuration) {
        // 缓存有效，直接返回
        return cached;
      }
      // 缓存过期，清除旧缓存
      _cache.remove(cosPath);
      _cacheTime.remove(cosPath);
    }

    // 从后端获取新的签名 URL
    final url = await TencentService.to.getPresignedUrl(cosPath);
    if (url != null) {
      // 存入缓存
      _cache[cosPath] = url;
      _cacheTime[cosPath] = DateTime.now();
    }
    return url;
  }

  /// 获取缓存的签名 URL（同步方法，不请求后端）
  /// 
  /// 用于需要同步获取 URL 的场景
  /// 如果缓存不存在或已过期，返回 null
  /// 
  /// [cosPath] COS 路径
  /// 返回: 缓存的签名 URL，不存在则返回 null
  String? getCachedUrl(String cosPath) {
    if (cosPath.isEmpty) return null;
    
    // 如果是完整 URL，直接返回
    if (cosPath.startsWith('http://') || cosPath.startsWith('https://')) {
      return cosPath;
    }
    
    return _cache[cosPath];
  }

  /// 判断是否为 COS 路径（非完整 URL）
  /// 
  /// 用于判断需要获取签名 URL 还是直接使用原 URL
  /// 
  /// [url] 待判断的路径或 URL
  /// 返回: true 表示是 COS 路径，需要获取签名；false 表示是完整 URL
  bool isCosPath(String? url) {
    if (url == null || url.isEmpty) return false;
    return !url.startsWith('http://') && !url.startsWith('https://');
  }

  /// 使指定路径的缓存失效
  /// 
  /// 当文件被更新或删除时调用，确保下次获取新的签名 URL
  /// 
  /// [cosPath] COS 路径
  void invalidate(String cosPath) {
    _cache.remove(cosPath);
    _cacheTime.remove(cosPath);
  }

  /// 清除所有缓存
  /// 
  /// 用于用户退出登录等需要清除所有缓存的场景
  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }
}
