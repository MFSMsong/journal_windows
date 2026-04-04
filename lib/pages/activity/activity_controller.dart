import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/routers.dart';
import 'package:journal_windows/utils/toast_util.dart';

/// 账本控制器
class ActivityController extends GetxController {
  final Activity? activity;

  ActivityController(this.activity);

  final ActivityService _activityService = ActivityService.to;

  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  final descriptionController = TextEditingController();

  final budgetType = 'monthly'.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  @override
  void onClose() {
    nameController.dispose();
    budgetController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// 初始化数据
  void _initData() {
    if (activity != null) {
      nameController.text = activity!.activityName;
      budgetController.text = activity!.budget?.toString() ?? '';
      descriptionController.text = activity!.description ?? '';
      budgetType.value = activity!.budgetType ?? 'monthly';
    }
  }

  /// 设置预算类型
  void setBudgetType(String type) {
    budgetType.value = type;
  }

  /// 创建账本
  Future<void> create() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ToastUtil.showInfo('请输入账本名称');
      return;
    }

    final budget = budgetController.text.isNotEmpty
        ? double.tryParse(budgetController.text)
        : null;

    final newActivity = Activity(
      activityId: '',
      activityName: name,
      userId: '',
      creatorName: '',
      budget: budget,
      budgetType: budget != null ? budgetType.value : null,
      description: descriptionController.text.trim(),
      activated: true,
      createTime: '',
      expenseList: [],
      userList: [],
    );

    await _activityService.createActivity(
      newActivity,
      onSuccess: (msg) {
        ToastUtil.closePage(result: true);
        ToastUtil.showSuccess(msg);
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }

  /// 保存修改
  Future<void> save() async {
    if (activity == null) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      ToastUtil.showInfo('请输入账本名称');
      return;
    }

    final budget = budgetController.text.isNotEmpty
        ? double.tryParse(budgetController.text)
        : null;

    final updatedActivity = activity!.copyWith(
      activityName: name,
      budget: budget,
      budgetType: budget != null ? budgetType.value : null,
      description: descriptionController.text.trim(),
    );

    await _activityService.updateActivity(
      updatedActivity,
      onSuccess: (msg) {
        ToastUtil.closePage(result: true);
        ToastUtil.showSuccess(msg);
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }

  /// 删除账本
  Future<void> delete() async {
    if (activity == null) return;

    await _activityService.deleteActivity(
      activity!.activityId,
      onSuccess: (msg) {
        ToastUtil.closePage(result: true);
        ToastUtil.showSuccess(msg);
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }
}