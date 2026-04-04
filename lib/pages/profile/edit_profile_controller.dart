import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:journal_windows/models/user.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/services/tencent_service.dart';
import 'package:journal_windows/utils/toast_util.dart';
import 'package:journal_windows/utils/image_crop_util.dart';

/// 编辑个人信息控制器
class EditProfileController extends GetxController {
  final UserService _userService = UserService.to;

  final nicknameController = TextEditingController();
  final openingStatementController = TextEditingController();
  final salutationController = TextEditingController();

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
    salutationController.dispose();
    super.onClose();
  }

  /// 初始化数据
  void _initData() {
    final user = _userService.currentUser.value;
    if (user != null) {
      nicknameController.text = user.nickname;
      avatarUrl.value = user.avatarUrl;
      openingStatementController.text = user.openingStatement ?? '';
      salutationController.text = user.salutation ?? '';
    }
  }

  /// 保存
  Future<void> save() async {
    if (isSaving.value) return;
    isSaving.value = true;
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      ToastUtil.showInfo('请输入昵称');
      isSaving.value = false;
      return;
    }

    final user = _userService.currentUser.value;
    if (user == null) {
      ToastUtil.showError('用户未登录');
      isSaving.value = false;
      return;
    }

    final updatedUser = User(
      userId: user.userId,
      nickname: nickname,
      avatarUrl: avatarUrl.value,
      openid: user.openid,
      vip: user.vip,
      telephone: user.telephone,
      currentActivityId: user.currentActivityId,
      openingStatement: openingStatementController.text.trim(),
      salutation: salutationController.text.trim(),
      relationship: user.relationship,
      personality: user.personality,
      aiAvatarUrl: user.aiAvatarUrl,
      createTime: user.createTime,
    );

    await _userService.updateUser(
      updatedUser,
      onSuccess: (msg) {
        isSaving.value = false;
        ToastUtil.closePage();
        ToastUtil.showSuccess(msg);
      },
      onFail: (msg) {
        ToastUtil.showError(msg);
        isSaving.value = false;
      },
    );
  }

  /// 选择并上传头像
  Future<void> pickAndUploadAvatar(dynamic context) async {
    try {
      // 1. 选择图片
      final imagePath = await ImageCropUtil.pickAndCropImage(context);
      if (imagePath == null) return;

      // 2. 检查用户登录状态
      final user = _userService.currentUser.value;
      if (user == null) {
        ToastUtil.showError('用户未登录');
        return;
      }

      // 3. 显示上传中
      ToastUtil.showInfo('上传中...');

      // 4. 上传文件到 COS
      final url = await TencentService.to.uploadAvatar(imagePath, user.userId);

      if (url != null) {
        // 更新头像 URL
        avatarUrl.value = url;
        ToastUtil.showSuccess('头像上传成功，点击保存以更新');
      } else {
        ToastUtil.showError('头像上传失败，请重试');
      }
    } catch (e) {
      print('选择或上传头像失败: $e');
      ToastUtil.showError('上传失败: $e');
    }
  }
}