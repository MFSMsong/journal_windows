/// 账本成员模型
class ActivityMember {
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String? activityNickname;
  final bool isOwner;
  final String? joinTime;

  ActivityMember({
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.activityNickname,
    required this.isOwner,
    this.joinTime,
  });

  factory ActivityMember.fromJson(Map<String, dynamic> json) {
    return ActivityMember(
      userId: json['userId'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'],
      activityNickname: json['activityNickname'],
      isOwner: json['isOwner'] == true || json['isOwner'] == 1,
      joinTime: json['joinTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'activityNickname': activityNickname,
      'isOwner': isOwner,
      'joinTime': joinTime,
    };
  }

  /// 获取显示名称（优先显示账本内昵称）
  String get displayName => activityNickname?.isNotEmpty == true ? activityNickname! : nickname;

  @override
  String toString() {
    return 'ActivityMember{userId: $userId, nickname: $nickname, activityNickname: $activityNickname, isOwner: $isOwner}';
  }
}
