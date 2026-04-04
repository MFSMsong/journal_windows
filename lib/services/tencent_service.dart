import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';

/// 腾讯云服务
class TencentService extends GetxService {
  static TencentService get to => Get.find();

  static void init() {
    Get.put(TencentService());
  }

  // ==================== 配置信息（请确保与后端一致）====================
  static const String _bucket = 'accouting-1417948476';  // 存储桶名称
  static const String _region = 'ap-chengdu';        // 存储桶地域
  static const String _cdnHost = 'https://accouting-1417948476.cos.ap-chengdu.myqcloud.com';  // CDN 域名或 COS 域名
  // =================================================================

  /// 获取 COS 临时凭证
  Future<CosCredential?> getCosCredential() async {
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getCosCredential(),
      );
      if (result != null) {
        return CosCredential.fromJson(result);
      }
    } catch (e) {
      print('获取COS凭证失败: $e');
    }
    return null;
  }

  /// 上传头像到 COS
  ///
  /// [filePath] 本地文件路径
  /// [userId] 用户ID
  /// 返回: 成功返回完整 CDN URL，失败返回 null
  Future<String?> uploadAvatar(String filePath, String userId) async {
    try {
      // 1. 获取临时凭证
      final credential = await getCosCredential();
      if (credential == null) {
        throw Exception('获取上传凭证失败');
      }

      // 2. 读取文件
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final bytes = await file.readAsBytes();
      final ext = path.extension(filePath).toLowerCase();
      final mimeType = _getMimeType(ext);

      // 3. 生成 COS 路径: Image/Avatar/{uuid}.png (一级目录，兼容 allowPrefix)
      final uuid = DateTime.now().millisecondsSinceEpoch.toString();
      final cosPath = 'Image/Avatar/$uuid$ext';

      // 4. 构造上传 URL
      final uploadUrl = 'https://$_bucket.cos.$_region.myqcloud.com/$cosPath';

      // 5. 使用临时密钥构造签名并上传
      final auth = _buildAuthorization(
        method: 'PUT',
        path: '/$cosPath',
        secretId: credential.tmpSecretId,
        secretKey: credential.tmpSecretKey,
        sessionToken: credential.sessionToken,
        contentType: mimeType,
      );

      print('上传URL: $uploadUrl');
      print('Content-Type: $mimeType');
      print('文件大小: ${bytes.length} bytes');
      print('Authorization: $auth');
      print('SessionToken: ${credential.sessionToken}');

      final dio = Dio();
      final response = await dio.put(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Authorization': auth,
            'x-cos-security-token': credential.sessionToken,
            'Content-Type': mimeType,
            'Content-Length': bytes.length.toString(),
            'Host': '$_bucket.cos.$_region.myqcloud.com',
          },
          contentType: mimeType,
          validateStatus: (status) => true, // 接受所有状态码以便调试
        ),
      );

      print('响应状态码: ${response.statusCode}');
      print('响应头: ${response.headers}');
      print('响应数据: ${response.data}');

      if (response.statusCode == 200) {
        // 返回 CDN URL
        final cdnUrl = '$_cdnHost/$cosPath';
        print('上传成功，CDN URL: $cdnUrl');
        return cdnUrl;
      } else {
        throw Exception('上传失败: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      print('上传头像失败: $e');
      return null;
    }
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

  /// 构建 COS 签名 (Key-Time 格式)
  /// 参考腾讯云官方文档: https://cloud.tencent.com/document/product/436/7778
  String _buildAuthorization({
    required String method,
    required String path,
    required String secretId,
    required String secretKey,
    required String sessionToken,
    required String contentType,
  }) {
    // 时间戳
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final startTime = now;
    final endTime = now + 1800; // 30分钟有效期

    final keyTime = '$startTime;$endTime';
    final signTime = '$startTime;$endTime';

    // 计算 SignKey (HMAC-SHA1(keyTime, SecretKey))
    final signKey = _hmacSha1Hex(keyTime, secretKey);

    // HttpHeaders - 需要签名的头部（按字典序）
    // key 转小写，value 需要 URL 编码（使用大写格式 %XX）
    final host = '$_bucket.cos.$_region.myqcloud.com';
    final headerMap = {
      'content-type': contentType,
      'host': host,
    };
    final sortedHeaders = headerMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    
    // header-list: key 列表，小写，分号分隔
    final headerList = sortedHeaders.map((e) => e.key.toLowerCase()).join(';');
    
    // http-headers: key=value 形式，value 需要 URL 编码（大写），key 小写
    final httpHeaders = sortedHeaders.map((e) {
      final key = e.key.toLowerCase();
      final value = Uri.encodeComponent(e.value);
      return '$key=$value';
    }).join('&');

    // HttpParameters - URL 参数（为空）
    final urlParamList = '';
    final httpParameters = '';

    // FormatString
    // 注意：path 保持原始大小写（如 /Image/Avatar/...）
    final formatString = '${method.toLowerCase()}\n$path\n$httpParameters\n$httpHeaders\n';

    print('FormatString: $formatString');

    // StringToSign
    final formatStringHash = _sha1Hex(formatString);
    final stringToSign = 'sha1\n$signTime\n$formatStringHash\n';

    print('StringToSign: $stringToSign');

    // Signature (HMAC-SHA1(StringToSign, SignKey))
    final signature = _hmacSha1Hex(stringToSign, signKey);

    print('Signature: $signature');

    // 最终 Authorization
    final auth = 'q-sign-algorithm=sha1'
        '&q-ak=$secretId'
        '&q-sign-time=$signTime'
        '&q-key-time=$keyTime'
        '&q-header-list=$headerList'
        '&q-url-param-list=$urlParamList'
        '&q-signature=$signature';

    print('Final Auth: $auth');

    return auth;
  }

  /// SHA1 哈希（返回十六进制小写字符串）
  String _sha1Hex(String data) {
    final bytes = utf8.encode(data);
    final digest = sha1.convert(bytes);
    return digest.toString().toLowerCase();
  }

  /// HMAC-SHA1（返回十六进制小写字符串）
  String _hmacSha1Hex(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha1, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString().toLowerCase();
  }
}

/// COS 临时凭证模型
class CosCredential {
  final String tmpSecretId;
  final String tmpSecretKey;
  final String sessionToken;
  final int startTime;
  final int expiredTime;

  CosCredential({
    required this.tmpSecretId,
    required this.tmpSecretKey,
    required this.sessionToken,
    required this.startTime,
    required this.expiredTime,
  });

  factory CosCredential.fromJson(Map<String, dynamic> json) {
    return CosCredential(
      tmpSecretId: json['secretId'] ?? '',
      tmpSecretKey: json['secretKey'] ?? '',
      sessionToken: json['sessionToken'] ?? '',
      startTime: json['startTime'] ?? 0,
      expiredTime: json['expiredTime'] ?? 0,
    );
  }
}
