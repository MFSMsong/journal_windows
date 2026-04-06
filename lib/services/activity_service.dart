import 'package:get/get.dart';
import 'package:journal_windows/models/activity.dart';
import 'package:journal_windows/models/activity_member.dart';
import 'package:journal_windows/request/request.dart';
import 'package:journal_windows/config/api_config.dart';
import 'package:journal_windows/services/storage_service.dart';

/// 账本服务
class ActivityService extends GetxService {
  static ActivityService get to => Get.find();
  
  final RxList<Activity> myActivities = <Activity>[].obs;
  final RxList<Activity> joinedActivities = <Activity>[].obs;
  final Rx<Activity?> currentActivity = Rx<Activity?>(null);
  final RxBool isLoading = false.obs;
  final RxList<ActivityMember> currentMembers = <ActivityMember>[].obs;

  /// 获取我的账本列表
  Future<List<Activity>> getMyActivities() async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getActivityList(),
      );
      
      if (result != null) {
        myActivities.value = result.map((e) => Activity.fromJson(e)).toList();
        return myActivities;
      }
    } catch (e) {
      print('获取我的账本列表失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  /// 获取加入的账本列表
  Future<List<Activity>> getJoinedActivities() async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getJoinedActivityList(),
      );
      
      if (result != null) {
        joinedActivities.value = result.map((e) => Activity.fromJson(e)).toList();
        return joinedActivities;
      }
    } catch (e) {
      print('获取加入的账本列表失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  /// 获取当前账本
  Future<Activity?> getCurrentActivity() async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<Map<String, dynamic>>(
        ApiConfig.getCurrentActivity(),
      );
      
      if (result != null) {
        currentActivity.value = Activity.fromJson(result);
        await StorageService.setCurrentActivityId(currentActivity.value!.activityId);
        return currentActivity.value;
      }
    } catch (e) {
      print('获取当前账本失败: $e');
    } finally {
      isLoading.value = false;
    }
    return null;
  }

  /// 创建账本 - 完全仿照 Android 项目的方式
  Future<bool> createActivity(Activity activity, {Function(String)? onSuccess, Function(String)? onFail}) async {
    print('createActivity 被调用');
    isLoading.value = true;
    
    await HttpRequest.request(
      Method.post,
      ApiConfig.createActivity(),
      params: activity.toJson(),
      success: (data) {
        print('HttpRequest.request success 回调被调用, data=$data');
        isLoading.value = false;
        if (data != null && data is Map<String, dynamic>) {
          final createdActivity = Activity.fromJson(data);
          myActivities.insert(0, createdActivity);
        }
        print('准备调用 onSuccess 回调');
        onSuccess?.call('创建成功');
        print('onSuccess 回调调用完成');
      },
      fail: (code, msg) {
        print('HttpRequest.request fail 回调被调用, code=$code, msg=$msg');
        isLoading.value = false;
        onFail?.call(msg);
      },
    );
    
    print('HttpRequest.request 调用完成');
    return false;
  }

  /// 更新账本 - 完全仿照 Android 项目的方式
  Future<bool> updateActivity(Activity activity, {Function(String)? onSuccess, Function(String)? onFail}) async {
    isLoading.value = true;
    
    await HttpRequest.request(
      Method.patch,
      ApiConfig.updateActivity(),
      params: activity.toJson(),
      success: (data) {
        isLoading.value = false;
        // 更新列表中的账本
        final index = myActivities.indexWhere((a) => a.activityId == activity.activityId);
        if (index != -1) {
          myActivities[index] = activity;
        }
        onSuccess?.call('更新成功');
      },
      fail: (code, msg) {
        isLoading.value = false;
        onFail?.call(msg);
      },
    );
    
    return false;
  }

  /// 删除账本
  Future<bool> deleteActivity(String activityId, {Function(String)? onSuccess, Function(String)? onFail}) async {
    isLoading.value = true;
    
    await HttpRequest.request(
      Method.delete,
      ApiConfig.deleteActivity(activityId),
      success: (data) {
        isLoading.value = false;
        myActivities.removeWhere((a) => a.activityId == activityId);
        joinedActivities.removeWhere((a) => a.activityId == activityId);
        if (currentActivity.value?.activityId == activityId) {
          currentActivity.value = null;
        }
        onSuccess?.call('删除成功');
      },
      fail: (code, msg) {
        isLoading.value = false;
        onFail?.call(msg);
      },
    );
    
    return false;
  }

  /// 加入账本
  Future<bool> joinActivity(String activityId, {Function(String)? onSuccess, Function(String)? onFail}) async {
    isLoading.value = true;
    
    try {
      await HttpRequest.request(
        Method.post,
        ApiConfig.joinActivity(activityId),
        success: (data) {
          isLoading.value = false;
          onSuccess?.call('加入成功');
        },
        fail: (code, msg) {
          isLoading.value = false;
          onFail?.call(msg);
        },
      );
      return true;
    } catch (e) {
      isLoading.value = false;
      onFail?.call(e.toString());
      return false;
    }
  }

  /// 退出账本
  Future<bool> exitActivity(String activityId, {Function(String)? onSuccess, Function(String)? onFail}) async {
    isLoading.value = true;

    await HttpRequest.request(
      Method.post,
      ApiConfig.exitActivity(activityId),
      success: (data) {
        isLoading.value = false;
        joinedActivities.removeWhere((a) => a.activityId == activityId);

        // 如果退出的是当前选中的账本，清空当前账本
        if (currentActivity.value?.activityId == activityId) {
          currentActivity.value = null;
          StorageService.removeCurrentActivityId();
        }

        onSuccess?.call('退出成功');
      },
      fail: (code, msg) {
        isLoading.value = false;
        onFail?.call(msg);
      },
    );

    return false;
  }

  /// 设置当前账本
  void setCurrentActivity(Activity? activity) {
    currentActivity.value = activity;
    if (activity != null) {
      StorageService.setCurrentActivityId(activity.activityId);
    }
  }

  /// 清理缓存 - 退出登录时调用
  void clearCache() {
    myActivities.clear();
    joinedActivities.clear();
    currentActivity.value = null;
    isLoading.value = false;
    currentMembers.clear();
  }

  /// 获取账本成员列表
  Future<List<ActivityMember>> getActivityMembers(String activityId) async {
    isLoading.value = true;
    try {
      final result = await HttpRequest.get<List<dynamic>>(
        ApiConfig.getActivityMembers(activityId),
      );
      
      if (result != null) {
        currentMembers.value = result.map((e) => ActivityMember.fromJson(e as Map<String, dynamic>)).toList();
        return currentMembers;
      }
    } catch (e) {
      print('获取账本成员列表失败: $e');
    } finally {
      isLoading.value = false;
    }
    return [];
  }

  /// 设置账本内昵称
  Future<bool> updateNickname(String activityId, String nickname, {String? targetUserId, Function(String)? onSuccess, Function(String)? onFail}) async {
    isLoading.value = true;
    
    await HttpRequest.request(
      Method.post,
      ApiConfig.updateActivityNickname(),
      params: {
        'activityId': activityId,
        'nickname': nickname,
        if (targetUserId != null) 'targetUserId': targetUserId,
      },
      success: (data) {
        isLoading.value = false;
        onSuccess?.call('设置成功');
      },
      fail: (code, msg) {
        isLoading.value = false;
        onFail?.call(msg);
      },
    );
    
    return false;
  }

  /// 踢出成员（仅创建者可用）
  Future<bool> kickMember(String activityId, String userId, {Function(String)? onSuccess, Function(String)? onFail}) async {
    isLoading.value = true;
    
    await HttpRequest.request(
      Method.delete,
      ApiConfig.kickMember(activityId, userId),
      success: (data) {
        isLoading.value = false;
        onSuccess?.call('移除成功');
      },
      fail: (code, msg) {
        isLoading.value = false;
        onFail?.call(msg);
      },
    );
    
    return false;
  }
}
