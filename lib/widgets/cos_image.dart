import 'package:flutter/material.dart';
import 'package:journal_windows/services/cos_url_service.dart';

class CosImage extends StatefulWidget {
  final String cosPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
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
  String? _signedUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  @override
  void didUpdateWidget(CosImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cosPath != widget.cosPath) {
      _isLoading = true;
      _hasError = false;
      _loadSignedUrl();
    }
  }

  Future<void> _loadSignedUrl() async {
    if (widget.cosPath.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    if (widget.cosPath.startsWith('http://') || widget.cosPath.startsWith('https://')) {
      if (mounted) {
        setState(() {
          _signedUrl = widget.cosPath;
          _isLoading = false;
        });
      }
      return;
    }

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
    if (_isLoading) {
      return widget.placeholder ?? _buildDefaultPlaceholder();
    }

    if (_hasError || _signedUrl == null) {
      return widget.errorWidget ?? _buildDefaultError();
    }

    Widget image = Image.network(
      _signedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? _buildDefaultError();
      },
    );

    if (widget.borderRadius != null) {
      image = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: image,
      );
    }

    return image;
  }

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
