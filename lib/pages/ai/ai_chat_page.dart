import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/ai/ai_chat_controller.dart';

/// AI聊天页面
/// 提供用户与AI理财助手的聊天界面
/// 支持流式响应、财务数据上下文、消息复制等功能
class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AiChatController());

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(context, controller),
          const Divider(height: 1),
          Expanded(
            child: Obx(() => _buildMessageList(context, controller)),
          ),
          const Divider(height: 1),
          _buildInputArea(context, controller),
        ],
      ),
    );
  }

  /// 构建页面头部
  /// 包含AI图标、标题、财务数据开关和清空按钮
  Widget _buildHeader(BuildContext context, AiChatController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // AI图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.purple[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // 标题和副标题
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI理财助手',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '随时为您提供理财建议',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // 功能按钮区域
          Obx(() => Row(
            children: [
              // 财务数据开关按钮
              Tooltip(
                message: controller.includeFinancialData.value ? '已包含财务数据' : '不包含财务数据',
                child: InkWell(
                  onTap: controller.toggleFinancialData,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: controller.includeFinancialData.value 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.analytics,
                      size: 18,
                      color: controller.includeFinancialData.value 
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 清空聊天按钮
              Tooltip(
                message: '清空聊天',
                child: InkWell(
                  onTap: controller.clearMessages,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  /// 构建消息列表
  /// 显示所有聊天消息，支持滚动
  Widget _buildMessageList(BuildContext context, AiChatController controller) {
    final messages = controller.messages;

    if (messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageItem(context, message, controller);
      },
    );
  }

  /// 构建空状态提示
  /// 当没有消息时显示引导文字
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            '开始和AI助手聊天吧',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '可以询问理财建议或日常聊天',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单条消息项
  /// 根据消息类型（用户/AI）显示不同的样式
  /// 使用SelectableText支持消息复制
  Widget _buildMessageItem(BuildContext context, ChatMessage message, AiChatController controller) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI消息显示AI头像
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.purple[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // 消息气泡
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
              ),
              // 使用SelectableText支持消息复制
              child: SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // 用户消息显示用户头像
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: controller.userService.currentUser.value?.avatarUrl.isNotEmpty == true
                  ? NetworkImage(controller.userService.currentUser.value!.avatarUrl)
                  : null,
              child: controller.userService.currentUser.value?.avatarUrl.isEmpty != false
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建输入区域
  /// 包含输入框和发送按钮
  Widget _buildInputArea(BuildContext context, AiChatController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 输入框
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: controller.inputController,
                focusNode: controller.focusNode,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendMessage(),
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 发送按钮
          Obx(() => Material(
            color: controller.isLoading.value 
                ? Colors.grey[300]
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: controller.isLoading.value ? null : controller.sendMessage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                // 加载中显示进度指示器，否则显示发送图标
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
