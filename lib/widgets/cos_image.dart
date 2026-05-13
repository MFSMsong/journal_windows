import 'package:flutter/material.dart';
import 'package:journal_windows/services/cos_url_service.dart';

/// COS 图片组件
/// 
/// 用于显示存储在腾讯云 COS 私有存储桶中的图片
/// 自动处理预签名 URL 的获取和缓存
/// 
/// 工作流程：
/// 1. 接收 COS 路径（如 Image/Avatar/xxx.jpg）
/// 2. 从 CosUrlService 获取带签名的临时访问 URL
/// 3. 使用签名 URL 加载并显示图片
/// 
/// 特性：
/// - 自动处理签名 URL 获取
/// - 支持加载状态占位符
/// - 支持错误状态显示
/// - 支持圆角图片
/// - 自动缓存签名 URL，避免重复请求
/// 
/// 使用示例：
/// ```dart
/// CosImage(
///   cosPath: 'Image/Avatar/xxx.jpg',
///   width: 100,
///   height: 100,
///   borderRadius: BorderRadius.circular(50),
/// )
/// ```
class CosImage extends StatefulWidget {
  /// COS 文件路径（如 Image/Avatar/xxx.jpg）
  /// 也可以传入完整的 URL，组件会自动识别
  final String cosPath;
  
  /// 图片宽度
  final double? width;
  
  /// 图片高度
  final double? height;
  
  /// 图片填充模式
  final BoxFit fit;
  
  /// 圆角
  final BorderRadius? borderRadius;
  
  /// 加载中占位符
  final Widget? placeholder;
  
  /// 错误状态显示
  final Widget? errorWidget;

  const CosImage({
    super.key,
    required this.cosPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CosImage> createState() => _CosImageState();
}

class _CosImageState extends State<CosImage> {
  /// 签名后的访问 URL
  String? _signedUrl;
  
  /// 是否正在加载签名 URL
  bool _isLoading = true;
  
  /// 是否发生错误
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  @override
  void didUpdateWidget(CosImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当图片路径变化时，重新加载签名 URL
    if (oldWidget.cosPath != widget.cosPath) {
      _isLoading = true;
      _hasError = false;
      _loadSignedUrl();
    }
  }

  /// 加载签名 URL
  /// 
  /// 工作流程：
  /// 1. 检查路径是否为空
  /// 2. 如果已经是完整 URL，直接使用
  /// 3. 否则从 CosUrlService 获取签名 URL
  Future<void> _loadSignedUrl() async {
    // 空路径处理
    if (widget.cosPath.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    // 如果已经是完整 URL，直接使用（外部链接）
    if (widget.cosPath.startsWith('http://') || widget.cosPath.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _signedUrl = widget.cosPath;
          _isLoading = false;
        });
      }
      return;
    }

    // 从 CosUrlService 获取签名 URL
    // CosUrlService 会自动处理缓存，避免重复请求后端
    try {
      final url = await CosUrlService.to.getSignedUrl(widget.cosPath);
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _isLoading = false;
          _hasError = url == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 加载中状态
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    // 错误状态
    if (_hasError || _signedUrl == null) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    // 使用签名 URL 加载图片
    Widget image = Image.network(
      _signedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // 图片加载失败时显示错误占位符
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? _buildDefaultError();
      },
    );

    // 如果需要圆角，用 ClipRRect 包裹
    if (widget.borderRadius != null) {
      image = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }

  /// 默认加载中占位符
  /// 显示半透明背景和加载动画
  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  /// 默认错误占位符
  /// 显示半透明背景和错误图标
  Widget _buildDefaultError() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: widget.borderRadius,
      ),
      child: Icon(
        Icons.broken_image_outlined,
        color: Colors.white.withValues(alpha: 0.3),
        size: (widget.width ?? 40) * 0.5,
      ),
    );
  }
}
