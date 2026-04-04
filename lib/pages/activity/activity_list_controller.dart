import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 账本列表控制器
class ActivityListController extends GetxController {
  final ActivityService _activityService = ActivityService.to;
  
  final searchController = TextEditingController();
  final RxList<Activity> myActivities = <Activity>[].obs;
  final RxList<Activity> joinedActivities = <Activity>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadActivities();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// 加载账本列表
  Future<void> loadActivities() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadMyActivities(),
        _loadJoinedActivities(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载我的账本
  Future<void> _loadMyActivities() async {
    final list = await _activityService.getMyActivities();
    myActivities.value = list;
  }

  /// 加载加入的账本
  Future<void> _loadJoinedActivities() async {
    final list = await _activityService.getJoinedActivities();
    joinedActivities.value = list;
  }

  /// 加入账本
  Future<void> joinActivity(String activityId) async {
    await _activityService.joinActivity(
      activityId,
      onSuccess: (msg) {
        ToastUtil.showSuccess(msg);
        searchController.clear();
        loadActivities();
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }

  /// 退出账本
  Future<void> exitActivity(String activityId) async {
    await _activityService.exitActivity(
      activityId,
      onSuccess: (msg) {
        ToastUtil.showSuccess(msg);
        loadActivities();
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }

  /// 删除账本
  Future<void> deleteActivity(String activityId) async {
    await _activityService.deleteActivity(
      activityId,
      onSuccess: (msg) {
        ToastUtil.showSuccess(msg);
        loadActivities();
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }
}