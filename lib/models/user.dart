/// 用户模型
class User {
  String userId;
  String nickname;
  String avatarUrl;
  String? openid;
  bool vip;
  String? telephone;
  String? email;
  String? currentActivityId;
  String? openingStatement;
  String? salutation;
  String? relationship;
  String? personality;
  String? aiAvatarUrl;
  String createTime;

  User({
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    this.openid,
    required this.vip,
    this.telephone,
    this.email,
    this.currentActivityId,
    this.openingStatement,
    this.salutation,
    this.relationship,
    this.personality,
    this.aiAvatarUrl,
    required this.createTime,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      nickname: json['nickname'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      openid: json['openid'],
      vip: json['vip'] ?? false,
      telephone: json['telephone'],
      email: json['email'],
      currentActivityId: json['currentActivityId'],
      openingStatement: json['openingStatement'],
      salutation: json['salutation'],
      relationship: json['relationship'],
      personality: json['personality'],
      aiAvatarUrl: json['aiAvatarUrl'],
      createTime: json['createTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'openid': openid,
      'vip': vip,
      'telephone': telephone,
      'email': email,
      'currentActivityId': currentActivityId,
      'openingStatement': openingStatement,
      'salutation': salutation,
      'relationship': relationship,
      'personality': personality,
      'aiAvatarUrl': aiAvatarUrl,
      'createTime': createTime,
    };
  }

  /// 复制并修改
  User copyWith({
    String? userId,
    String? nickname,
    String? avatarUrl,
    String? openid,
    bool? vip,
    String? telephone,
    String? email,
    String? currentActivityId,
    String? openingStatement,
    String? salutation,
    String? relationship,
    String? personality,
    String? aiAvatarUrl,
    String? createTime,
  }) {
    return User(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      openid: openid ?? this.openid,
      vip: vip ?? this.vip,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      currentActivityId: currentActivityId ?? this.currentActivityId,
      openingStatement: openingStatement ?? this.openingStatement,
      salutation: salutation ?? this.salutation,
      relationship: relationship ?? this.relationship,
      personality: personality ?? this.personality,
      aiAvatarUrl: aiAvatarUrl ?? this.aiAvatarUrl,
      createTime: createTime ?? this.createTime,
    );
  }

  /// 创建空用户
  static User empty() {
    return User(
      userId: '',
      nickname: '',
      avatarUrl: '',
      vip: false,
      email: '',
      createTime: '',
    );
  }

  @override
  String toString() {
    return 'User{userId: $userId, nickname: $nickname, vip: $vip}';
  }
}