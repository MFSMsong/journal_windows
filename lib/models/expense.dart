/// 账单模型
class Expense {
  String expenseId;
  String type;
  double price;
  double? originalPrice;
  String label;
  String userId;
  String activityId;
  int positive;
  String? userNickname;
  String? userAvatar;
  String expenseTime;
  String createTime;
  String? updateTime;
  List<String>? fileList;

  Expense({
    required this.expenseId,
    required this.type,
    required this.price,
    this.originalPrice,
    required this.label,
    required this.userId,
    required this.activityId,
    required this.positive,
    this.userNickname,
    this.userAvatar,
    required this.expenseTime,
    required this.createTime,
    this.updateTime,
    this.fileList,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      expenseId: json['expenseId'] ?? '',
      type: json['type'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice']?.toDouble(),
      label: json['label'] ?? '',
      userId: json['userId'] ?? '',
      activityId: json['activityId'] ?? '',
      positive: json['positive'] ?? 0,
      userNickname: json['userNickname'],
      userAvatar: json['userAvatar'],
      expenseTime: json['expenseTime'] ?? '',
      createTime: json['createTime'] ?? '',
      updateTime: json['updateTime'],
      fileList: json['fileList'] != null 
          ? List<String>.from(json['fileList']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseId': expenseId,
      'type': type,
      'price': price,
      'originalPrice': originalPrice,
      'label': label,
      'userId': userId,
      'activityId': activityId,
      'positive': positive,
      'userNickname': userNickname,
      'userAvatar': userAvatar,
      'expenseTime': expenseTime,
      'createTime': createTime,
      'updateTime': updateTime,
      'fileList': fileList,
    };
  }

  /// 是否为支出
  bool get isExpense => positive == 0;
  
  /// 是否为收入
  bool get isIncome => positive == 1;
  
  /// 是否有折扣
  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  
  /// 节省金额
  double get savedAmount => hasDiscount ? (originalPrice! - price) : 0;

  /// 创建空账单
  static Expense empty() {
    return Expense(
      expenseId: '',
      type: '',
      price: 0,
      label: '',
      userId: '',
      activityId: '',
      positive: 0,
      expenseTime: '',
      createTime: '',
      fileList: [],
    );
  }

  /// 复制并修改
  Expense copyWith({
    String? expenseId,
    String? type,
    double? price,
    double? originalPrice,
    String? label,
    String? userId,
    String? activityId,
    int? positive,
    String? userNickname,
    String? userAvatar,
    String? expenseTime,
    String? createTime,
    String? updateTime,
    List<String>? fileList,
  }) {
    return Expense(
      expenseId: expenseId ?? this.expenseId,
      type: type ?? this.type,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      label: label ?? this.label,
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      positive: positive ?? this.positive,
      userNickname: userNickname ?? this.userNickname,
      userAvatar: userAvatar ?? this.userAvatar,
      expenseTime: expenseTime ?? this.expenseTime,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      fileList: fileList ?? this.fileList,
    );
  }

  @override
  String toString() {
    return 'Expense{expenseId: $expenseId, type: $type, price: $price, label: $label, positive: $positive}';
  }
}
