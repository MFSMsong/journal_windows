import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// 图片选择工具类（简化版，暂不支持裁剪）
class ImageCropUtil {
  /// 选择图片文件
  /// 
  /// 返回图片路径，如果用户取消则返回 null
  static Future<String?> pickAndCropImage(dynamic context) async {
    // 选择图片
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    
    // 如果有 path 直接返回
    if (file.path != null) {
      return file.path;
    }
    
    // Windows 桌面端可能返回 bytes，保存到临时文件
    if (file.bytes != null) {
      return await _saveBytesToTempFile(file.bytes!, file.extension ?? 'jpg');
    }

    return null;
  }

  /// 将 bytes 保存到临时文件
  static Future<String?> _saveBytesToTempFile(Uint8List bytes, String ext) async {
    try {
      final tempDir = Directory.systemTemp;
      final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${tempDir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print('保存临时文件失败: $e');
      return null;
    }
  }
}
