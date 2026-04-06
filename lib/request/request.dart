import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/core/log.dart';
import 'package:journal_windows/routers.dart';
import 'package:journal_windows/services/storage_service.dart';

/// 连接超时时间
const Duration _connectTimeout = Duration(seconds: 30);

/// 发送超时时间
const Duration _sendTimeout = Duration(seconds: 30);

/// 接收超时时间
const Duration _receiveTimeout = Duration(seconds: 30);

/// 成功回调
typedef Success<T> = Function(T data);

/// 失败回调
typedef Fail = Function(int code, String msg);

/// 完成回调
typedef CompleteCallback = void Function();

/// HTTP请求方法
enum Method { get, post, delete, put, patch }

const _methodValues = {
  Method.get: 'GET',
  Method.post: 'POST',
  Method.delete: 'DELETE',
  Method.put: 'PUT',
  Method.patch: 'PATCH',
};

/// HTTP响应结果
class Result<T> {
  static const int successCode = 0;
  
  int? code;
  String? msg;
  T? data;

  Result({this.code, this.msg, this.data});

  factory Result.fromJson(Map<String, dynamic> json) {
    final rawCode = json['code'];
    int? parsedCode;
    
    if (rawCode is int) {
      parsedCode = rawCode;
    } else if (rawCode is num) {
      parsedCode = rawCode.toInt();
    } else if (rawCode is String) {
      parsedCode = int.tryParse(rawCode);
    }
    
    return Result<T>(
      code: parsedCode,
      msg: json['msg']?.toString(),
      data: json['data'],
    );
  }

  bool get isSuccess => code == successCode;
}

/// HTTP请求类
class HttpRequest {
  static Dio? _dio;

  static Dio get dio => createInstance();

  /// 创建dio实例
  static Dio createInstance() {
    if (_dio == null) {
      var options = BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        contentType: Headers.jsonContentType,
        validateStatus: (status) => status != null && status < 500,
        sendTimeout: _sendTimeout,
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      );
      _dio = Dio(options);
      
      _dio!.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = token;
          }
          
          options.headers.addAll(await _buildHeaders());
          
          Log().d('请求: ${options.method} ${options.path}');
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          Log().d('响应: ${response.statusCode}');
          
          final result = Result.fromJson(response.data);
          if (result.code == -1) {
            Log().d('Token失效');
            StorageService.clearToken();
            getx.Get.offAllNamed(Routers.LoginPageUrl);
          }
          
          return handler.next(response);
        },
        onError: (error, handler) {
          Log().e('请求错误: ${error.message}');
          
          if (error.response?.statusCode == 401) {
            StorageService.clearToken();
            getx.Get.offAllNamed(Routers.LoginPageUrl);
          }
          
          return handler.next(error);
        },
      ));
    }
    return _dio!;
  }

  /// 构建请求头
  static Future<Map<String, dynamic>> _buildHeaders() async {
    return {
      'x-wx-from-appid': 'wx2f6af8ec967dde40',
      'x-model-type': 'DESKTOP',
      'x-os-type': 'Windows',
      'x-os-version': Platform.operatingSystemVersion,
      'x-phone-model': 'Windows Desktop',
      'x-app-version': '1.0.0',
      'x-app-name': 'journal_windows',
      'x-app': 'app',
    };
  }

  /// 通用请求方法
  static Future<T?> request<T>(
    Method method,
    String path, {
    dynamic params,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? header,
    Success<T>? success,
    Fail? fail,
    CompleteCallback? complete,
    CancelToken? cancelToken,
    bool isStream = false,
  }) async {
    try {
      Dio dio = createInstance();
      Log().d('请求URL: $path');

      Response response = await dio.request(
        path,
        data: params,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: Options(
          method: _methodValues[method],
          headers: header,
          responseType: isStream ? ResponseType.stream : ResponseType.json,
        ),
      );

      if (isStream) {
        success?.call(response.data.stream as T);
        return Future.value(response.data.stream as T);
      }

      var result = Result.fromJson(response.data);
      Log().d('响应结果: code=${result.code}, msg=${result.msg}, isSuccess=${result.isSuccess}');
      
      if (response.statusCode == 200 && result.isSuccess) {
        // 成功时调用 success 回调
        Log().d('调用 success 回调');
        success?.call(result.data);
        return Future.value(result.data as T?);
      } else {
        // 失败时调用 fail 回调并返回 null
        Log().d('请求失败: code=${result.code}, msg=${result.msg}');
        fail?.call(result.code ?? -1, result.msg ?? '未知错误');
        return Future.value(null);
      }
    } on DioException catch (e) {
      final errorMsg = _handleDioError(e);
      Log().e('请求异常: $errorMsg');
      fail?.call(-1, errorMsg);
      return Future.value(null);
    } catch (e) {
      Log().e('未知异常: $e');
      fail?.call(-1, e.toString());
      return Future.value(null);
    } finally {
      complete?.call();
    }
  }

  /// 处理Dio错误
  static String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badResponse:
        return '服务器响应错误: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      case DioExceptionType.badCertificate:
        return '证书错误';
      case DioExceptionType.unknown:
        return '未知错误: ${e.message}';
    }
  }

  /// GET请求
  static Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Success<T>? success,
    Fail? fail,
    CompleteCallback? complete,
  }) {
    return request<T>(
      Method.get,
      path,
      queryParameters: queryParameters,
      success: success,
      fail: fail,
      complete: complete,
    );
  }

  /// POST请求
  static Future<T?> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Success<T>? success,
    Fail? fail,
    CompleteCallback? complete,
  }) {
    return request<T>(
      Method.post,
      path,
      params: data,
      queryParameters: queryParameters,
      success: success,
      fail: fail,
      complete: complete,
    );
  }

  /// PUT请求
  static Future<T?> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Success<T>? success,
    Fail? fail,
    CompleteCallback? complete,
  }) {
    return request<T>(
      Method.put,
      path,
      params: data,
      queryParameters: queryParameters,
      success: success,
      fail: fail,
      complete: complete,
    );
  }

  /// PATCH请求
  static Future<T?> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Success<T>? success,
    Fail? fail,
    CompleteCallback? complete,
  }) {
    return request<T>(
      Method.patch,
      path,
      params: data,
      queryParameters: queryParameters,
      success: success,
      fail: fail,
      complete: complete,
    );
  }

  /// DELETE请求
  static Future<T?> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Success<T>? success,
    Fail? fail,
    CompleteCallback? complete,
  }) {
    return request<T>(
      Method.delete,
      path,
      queryParameters: queryParameters,
      success: success,
      fail: fail,
      complete: complete,
    );
  }
}