import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/services/storage_service.dart';
import 'package:dio/dio.dart';

/// 聊天消息模型
/// 用于表示单条聊天消息的内容和属性
class ChatMessage {
  /// 消息内容
  final String content;
  
  /// 是否为用户发送的消息（true=用户，false=AI）
  final bool isUser;
  
  /// 消息发送时间
  final DateTime time;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

/// AI聊天控制器
/// 管理聊天消息列表、发送消息、处理流式响应等
class AiChatController extends GetxController {
  /// 用户服务，用于获取用户信息
  final UserService userService = UserService.to;
  
  /// 消息输入框控制器
  final inputController = TextEditingController();
  
  /// 输入框焦点节点
  final focusNode = FocusNode();
  
  /// 消息列表滚动控制器
  final scrollController = ScrollController();
  
  /// 聊天消息列表（响应式）
  final messages = <ChatMessage>[].obs;
  
  /// 是否正在加载（等待AI响应）
  final isLoading = false.obs;
  
  /// 是否在消息中包含财务数据
  /// 开启后AI会结合用户的账本数据提供个性化建议
  final includeFinancialData = true.obs;

  @override
  void onInit() {
    super.onInit();
    _addWelcomeMessage();
  }

  @override
  void onClose() {
    inputController.dispose();
    focusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// 添加欢迎消息
  /// 根据用户的称呼设置生成个性化欢迎语
  void _addWelcomeMessage() {
    final user = userService.currentUser.value;
    final salutation = user?.salutation ?? '朋友';
    messages.add(ChatMessage(
      content: '你好$salutation！我是你的AI理财助手，有什么可以帮助你的吗？',
      isUser: false,
    ));
  }

  /// 切换是否包含财务数据
  void toggleFinancialData() {
    includeFinancialData.value = !includeFinancialData.value;
  }

  /// 清空聊天记录
  /// 清空后会重新添加欢迎消息
  void clearMessages() {
    messages.clear();
    _addWelcomeMessage();
  }

  /// 发送消息
  /// 将用户消息添加到列表，然后发送请求获取AI响应
  Future<void> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isLoading.value) return;

    // 清空输入框，添加用户消息
    inputController.clear();
    messages.add(ChatMessage(content: text, isUser: true));
    _scrollToBottom();

    // 设置加载状态，添加AI消息占位
    isLoading.value = true;
    messages.add(ChatMessage(content: '', isUser: false));
    
    try {
      await _sendStreamRequest(text);
    } catch (e) {
      _updateLastMessage('抱歉，发生了错误：$e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 发送流式请求
  /// 通过SSE(Server-Sent Events)方式接收AI响应
  /// 实时更新消息内容，实现打字机效果
  /// 
  /// [message] 用户发送的消息内容
  Future<void> _sendStreamRequest(String message) async {
    // 获取认证Token
    final token = StorageService.getToken();
    if (token == null) return;

    // 创建独立的Dio实例
    // 使用独立实例是为了绕过全局拦截器，避免响应类型冲突
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ));

    // 发送GET请求，设置响应类型为stream
    final response = await dio.get<ResponseBody>(
      ApiConfig.aiChat,
      queryParameters: {
        'message': message,
        'includeFinancialData': includeFinancialData.value,
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
          'Authorization': token,
        },
      ),
    );

    final stream = response.data?.stream;
    if (stream == null) {
      throw Exception('响应流为空');
    }

    // 使用StringBuffer累积响应内容
    final buffer = StringBuffer();
    
    // 逐块读取流数据
    await for (var data in stream) {
      // 将字节解码为UTF-8字符串
      final bytes = data as List<int>;
      final decodedData = utf8.decode(bytes);
      
      // 累积内容并更新UI
      buffer.write(decodedData);
      _updateLastMessage(buffer.toString());
      _scrollToBottom();
    }
  }

  /// 更新最后一条消息内容
  /// 用于实时更新AI响应内容
  /// 
  /// [content] 新的消息内容
  void _updateLastMessage(String content) {
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = ChatMessage(
        content: content,
        isUser: false,
        time: messages.last.time,
      );
    }
  }

  /// 滚动到底部
  /// 在新消息添加后自动滚动到最新消息
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
