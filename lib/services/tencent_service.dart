import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:path/path.dart' as path;

/// 腾讯云服务
class TencentService extends GetxService {
  static TencentService get to => Get.find();

  static void init() {
    Get.put(TencentService());
  }

  /// 获取上传凭证
  ///
  /// [type] 上传类型: avatar 或 bill
  /// [ext] 文件扩展名（如 .jpg, .png）
  /// 返回: 成功返回 UploadCredential，失败返回 null
  Future<UploadCredential?> getUploadCredential(String type, String ext) async {
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getCosUploadCredential(),
        queryParameters: {'type': type, 'ext': ext},
      );
      if (result != null) {
        return UploadCredential.fromJson(result);
      }
    } catch (e) {
      print('获取上传凭证失败: $e');
    }
    return null;
  }

  /// 上传头像到 COS
  ///
  /// [filePath] 本地文件路径
  /// [userId] 用户ID
  /// 返回: 成功返回 COS 路径（不含域名），失败返回 null
  Future<String?> uploadAvatar(String filePath, String userId) async {
    return _uploadFile(filePath, 'avatar');
  }

  /// 上传账单附件图片到 COS
  ///
  /// [filePath] 本地文件路径
  /// [userId] 用户ID（用于生成安全文件名）
  /// 返回: 成功返回 COS 路径（不含域名），失败返回 null
  Future<String?> uploadBillImage(String filePath, String userId) async {
    return _uploadFile(filePath, 'bill');
  }

  /// 通用上传方法
  ///
  /// [filePath] 本地文件路径
  /// [type] 上传类型: avatar 或 bill
  /// 返回: 成功返回 COS 路径，失败返回 null
  Future<String?> _uploadFile(String filePath, String type) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final ext = path.extension(filePath).toLowerCase();
      final credential = await getUploadCredential(type, ext);
      if (credential == null) {
        throw Exception('获取上传凭证失败');
      }

      final bytes = await file.readAsBytes();
      final mimeType = _getMimeType(ext);

      final dio = Dio();
      final response = await dio.put(
        credential.uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': bytes.length.toString(),
          },
          contentType: mimeType,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200) {
        return credential.cosPath;
      } else {
        throw Exception('上传失败: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      print('上传文件失败: $e');
      return null;
    }
  }

  /// 获取私有文件的预签名URL
  ///
  /// [cosPath] COS路径（如 Image/Bill/xxx.jpg）
  /// 返回: 带签名的临时访问URL，有效期30分钟
  Future<String?> getPresignedUrl(String cosPath) async {
    try {
      final result = await HttpRequest.get<String>(
        ApiConfig.getCosPresignedUrl(),
        queryParameters: {'cosPath': cosPath},
      );
      return result;
    } catch (e) {
      print('获取签名URL失败: $e');
    }
    return null;
  }

  /// 获取 MIME 类型
  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }
}

/// 上传凭证模型
class UploadCredential {
  final String uploadUrl;
  final String cosPath;

  UploadCredential({
    required this.uploadUrl,
    required this.cosPath,
  });

  factory UploadCredential.fromJson(Map<String, dynamic> json) {
    return UploadCredential(
      uploadUrl: json['uploadUrl'] ?? '',
      cosPath: json['cosPath'] ?? '',
    );
  }
}
