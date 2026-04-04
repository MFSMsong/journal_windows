import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/pages/expense/expense_list_page.dart';
import 'package:journal_windows/pages/activity/activity_list_page.dart';
import 'package:journal_windows/pages/charts/charts_page.dart';
import 'package:journal_windows/pages/profile/profile_page.dart';
import 'package:journal_windows/pages/asset/asset_list_page.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/asset_service.dart';
import 'package:journal_windows/routers.dart';

/// 主布局控制器
class MainLayoutController extends GetxController {
  final currentIndex = 0.obs;
  final UserService userService = UserService.to;
  final ActivityService activityService = ActivityService.to;
  final AssetService assetService = AssetService.to;

  /// 当前页面
  Widget get currentPage {
    switch (currentIndex.value) {
      case 0:
        return const ExpenseListPage();
      case 1:
        return const ActivityListPage();
      case 2:
        return const ChartsPage();
      case 3:
        return const AssetListPage();
      case 4:
        return const ProfilePage();
      default:
        return const ExpenseListPage();
    }
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  /// 初始化数据
  Future<void> _initData() async {
    await userService.getUserProfile();
    await activityService.getCurrentActivity();
    // 加载我的账本和加入的账本
    await activityService.getMyActivities();
    await activityService.getJoinedActivities();
  }

  /// 切换页面
  Future<void> changePage(int index) async {
    currentIndex.value = index;

    // 根据页面索引刷新数据
    switch (index) {
      case 0:
        // 账单页面：刷新当前账本和所有账本列表（我的+加入的）
        await activityService.getCurrentActivity();
        await activityService.getMyActivities();
        await activityService.getJoinedActivities();
        break;
      case 1:
        // 账本管理页面：刷新账本列表
        await activityService.getMyActivities();
        await activityService.getJoinedActivities();
        break;
      case 2:
        // 统计页面：暂不需要
        break;
      case 3:
        // 资产管理页面：刷新资产数据
        await assetService.refresh();
        break;
      case 4:
        // 个人信息页面：刷新用户信息
        await userService.getUserProfile();
        break;
    }
  }

  /// 登出
  Future<void> logout() async {
    Get.dialog(
      AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await userService.logout();
              Get.offAllNamed(Routers.LoginPageUrl);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}