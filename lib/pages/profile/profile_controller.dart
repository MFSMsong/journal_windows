import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/user.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/routers.dart';

/// 个人信息控制器
class ProfileController extends GetxController {
  final UserService userService = UserService.to;

  /// 刷新用户信息
  Future<void> refreshUserProfile() async {
    await userService.getUserProfile();
  }

  /// 发送删除账户验证码
  Future<bool> sendDeleteAccountEmailCode() async {
    return await userService.sendDeleteAccountEmailCode();
  }

  /// 删除账户
  Future<void> deleteAccount(String code) async {
    final success = await userService.deleteUser(code);
    if (success) {
      ToastUtil.showSuccess('账户已删除');
      Get.offAllNamed(Routers.LoginPageUrl);
    } else {
      ToastUtil.showError('删除账户失败，请重试');
    }
  }
}

/// 编辑个人信息控制器
class EditProfileController extends GetxController {
  final User? user;

  EditProfileController(this.user);

  final UserService _userService = UserService.to;

  final nicknameController = TextEditingController();
  final openingStatementController = TextEditingController();
  final avatarUrl = ''.obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  @override
  void onClose() {
    nicknameController.dispose();
    openingStatementController.dispose();
    super.onClose();
  }

  /// 初始化数据
  void _initData() {
    if (user != null) {
      nicknameController.text = user!.nickname;
      avatarUrl.value = user!.avatarUrl;
      openingStatementController.text = user!.openingStatement ?? '';
    }
  }

  /// 保存
  Future<void> save() async {
    if (isSaving.value) return;

    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      ToastUtil.showInfo('请输入昵称');
      return;
    }

    final currentUser = _userService.currentUser.value;
    if (currentUser == null) {
      ToastUtil.showError('用户未登录');
      return;
    }

    final updatedUser = currentUser.copyWith(
      nickname: nickname,
      openingStatement: openingStatementController.text.trim(),
      avatarUrl: avatarUrl.value,
    );

    await _userService.updateUser(
      updatedUser,
      onSuccess: (msg) {
        ToastUtil.showSuccess(msg);
        ToastUtil.closePage(result: true);
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
      },
    );
  }
}
