import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/request/request.dart';
import 'package:path/path.dart' as path;

/// 腾讯云 COS 服务类
/// 
/// 负责前端与腾讯云 COS 的交互，包括：
/// 1. 获取预签名上传 URL - 从后端获取带签名的上传地址
/// 2. 直接上传文件到 COS - 使用预签名 URL 上传，文件不经过后端
/// 3. 获取预签名下载 URL - 从后端获取带签名的下载地址
/// 
/// 安全设计：
/// - 前端不存储 SecretKey，所有签名由后端生成
/// - 文件直接上传到 COS，不占用后端带宽
/// - 预签名 URL 有时效性，过期自动失效
/// 
/// 上传流程：
/// 1. 前端调用 getUploadCredential() 从后端获取预签名 URL
/// 2. 后端生成安全的文件名和带签名的上传 URL
/// 3. 前端使用 Dio 直接向 COS 发送 PUT 请求上传文件
/// 4. 上传成功后，前端将 COS 路径存储到数据库
/// 
/// 下载流程：
/// 1. 前端调用 getPresignedUrl() 从后端获取带签名的下载 URL
/// 2. 前端使用签名 URL 加载图片或下载文件
/// 3. CosUrlService 会自动缓存签名 URL，避免重复请求
class TencentService extends GetxService {
  static TencentService get to => Get.find();

  static void init() {
    Get.put(TencentService());
  }

  /// 上传头像到 COS
  ///
  /// [filePath] 本地文件路径
  /// [userId] 用户ID（后端用于生成安全文件名）
  /// 返回: 成功返回 COS 路径（如 Image/Avatar/xxx.jpg），失败返回 null
  Future<String?> uploadAvatar(String filePath, String userId) async {
    return _uploadFile(filePath, 'avatar');
  }

  /// 上传账单附件图片到 COS
  ///
  /// [filePath] 本地文件路径
  /// [userId] 用户ID（后端用于生成安全文件名）
  /// 返回: 成功返回 COS 路径（如 Image/Bill/xxx.jpg），失败返回 null
  Future<String?> uploadBillImage(String filePath, String userId) async {
    return _uploadFile(filePath, 'bill');
  }

  /// 通用上传方法
  ///
  /// 工作流程：
  /// 1. 检查文件是否存在
  /// 2. 从后端获取预签名上传 URL 和 COS 路径
  /// 3. 读取文件内容并确定 MIME 类型
  /// 4. 使用预签名 URL 直接向 COS 发送 PUT 请求
  /// 5. 上传成功返回 COS 路径，用于存储到数据库
  ///
  /// [filePath] 本地文件路径
  /// [type] 上传类型: avatar（头像）或 bill（账单附件）
  /// 返回: 成功返回 COS 路径，失败返回 null
  Future<String?> _uploadFile(String filePath, String type) async {
    try {
      // 1. 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      // 2. 获取文件扩展名
      final ext = path.extension(filePath).toLowerCase();
      
      // 3. 从后端获取预签名上传凭证
      // 返回：uploadUrl（带签名的上传地址）和 cosPath（文件存储路径）
      final credential = await getUploadCredential(type, ext);
      if (credential == null) {
        throw Exception('获取上传凭证失败');
      }

      // 4. 读取文件内容为字节数组
      final bytes = await file.readAsBytes();
      
      // 5. 根据扩展名确定 MIME 类型
      final mimeType = _getMimeType(ext);

      // 6. 使用 Dio 直接向 COS 发送 PUT 请求上传文件
      // 注意：这里直接请求 COS，不经过我们的后端服务器
      final dio = Dio();
      final response = await dio.put(
        credential.uploadUrl,  // 预签名 URL（包含签名信息）
        data: bytes,           // 文件内容
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': bytes.length.toString(),
          },
          contentType: mimeType,
          validateStatus: (status) => true,  // 不自动抛出异常，手动处理状态码
        ),
      );

      // 7. 检查上传结果
      if (response.statusCode == 200) {
        // 上传成功，返回 COS 路径（用于存储到数据库）
        return credential.cosPath;
      } else {
        throw Exception('上传失败: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      print('上传文件失败: $e');
      return null;
    }
  }

  /// 获取私有文件的预签名下载 URL
  ///
  /// 用于访问私有存储桶中的文件
  /// 前端拿到签名 URL 后可以直接用于 Image.network 或下载
  ///
  /// [cosPath] COS路径（如 Image/Avatar/xxx.jpg）
  /// 返回: 带签名的临时访问 URL，有效期30分钟
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

  /// 获取上传凭证（预签名上传 URL）
  ///
  /// 从后端获取带签名的上传 URL 和文件存储路径
  /// 后端会生成安全的文件名并返回预签名 URL
  ///
  /// [type] 文件类型：avatar 或 bill
  /// [ext] 文件扩展名（如 .jpg、.png）
  /// 返回: UploadCredential 对象，包含 uploadUrl 和 cosPath
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

  /// 根据文件扩展名获取 MIME 类型
  ///
  /// [ext] 文件扩展名（如 .jpg、.png）
  /// 返回: MIME 类型字符串
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
        return 'application/octet-stream';
    }
  }
}

/// 上传凭证模型
///
/// 从后端获取的上传凭证，包含：
/// - uploadUrl: 带签名的上传 URL，前端直接用这个 URL 上传文件
/// - cosPath: 文件在 COS 中的存储路径，上传成功后存入数据库
class UploadCredential {
  /// 带签名的上传 URL
  /// 格式：https://bucket.cos.region.myqcloud.com/Image/Avatar/xxx.jpg?sign=xxx
  final String uploadUrl;
  
  /// 文件在 COS 中的存储路径
  /// 格式：Image/Avatar/xxx.jpg（不含域名）
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
