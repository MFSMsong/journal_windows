import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/main_layout_controller.dart';
import 'package:journal_windows/pages/ai/ai_chat_page.dart';

/// 主布局页面 - Windows桌面风格
class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainLayoutController());

    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(context, controller),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Obx(() => _buildContent(controller)),
          ),
          Obx(() => _buildAiPanel(context, controller)),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, MainLayoutController controller) {
    return Container(
      width: 200,
      color: Colors.white,
      child: Column(
        children: [
          _buildAppHeader(context),
          const Divider(),
          Expanded(
            child: Obx(() => _buildNavMenu(context, controller)),
          ),
          const Divider(),
          _buildAiButton(context, controller),
          _buildUserSection(context, controller),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '好享记账',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Windows 桌面版',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavMenu(BuildContext context, MainLayoutController controller) {
    final menuItems = [
      _NavItem(icon: Icons.receipt_long, label: '账单记录', index: 0),
      _NavItem(icon: Icons.folder, label: '账本管理', index: 1),
      _NavItem(icon: Icons.bar_chart, label: '数据统计', index: 2),
      _NavItem(icon: Icons.account_balance_wallet, label: '资产管理', index: 3),
      _NavItem(icon: Icons.person, label: '个人信息', index: 4),
    ];

    final currentIndex = controller.currentIndex.value;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = currentIndex == item.index;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[600],
              size: 22,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            selected: isSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () => controller.changePage(item.index),
          ),
        );
      },
    );
  }

  Widget _buildAiButton(BuildContext context, MainLayoutController controller) {
    return Obx(() {
      final isOpen = controller.isAiPanelOpen.value;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOpen 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(
            Icons.smart_toy,
            color: isOpen 
                ? Theme.of(context).primaryColor 
                : Colors.grey[600],
            size: 22,
          ),
          title: Text(
            'AI助手',
            style: TextStyle(
              color: isOpen 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[700],
              fontWeight: isOpen ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: controller.toggleAiPanel,
        ),
      );
    });
  }

  Widget _buildUserSection(BuildContext context, MainLayoutController controller) {
    return Obx(() {
      final user = controller.userService.currentUser;
      final hasUser = user.value != null;
      
      return Container(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: () => controller.changePage(4),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: hasUser && user.value!.avatarUrl.isNotEmpty
                      ? NetworkImage(user.value!.avatarUrl)
                      : null,
                  child: !hasUser || user.value!.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasUser ? user.value!.nickname : '未登录',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasUser && user.value!.vip == true)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 18),
                  tooltip: '退出登录',
                  onPressed: controller.logout,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildContent(MainLayoutController controller) {
    final currentIndex = controller.currentIndex.value;
    return controller.currentPage;
  }

  Widget _buildAiPanel(BuildContext context, MainLayoutController controller) {
    if (!controller.isAiPanelOpen.value) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VerticalDivider(thickness: 1, width: 1),
        SizedBox(
          width: controller.aiPanelWidth,
          child: const AiChatPage(),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem({required this.icon, required this.label, required this.index});
}