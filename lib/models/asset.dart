class Asset {
  String assetId;
  String userId;
  int assetType;
  String name;
  String? bankName;
  String? cardLastFour;
  double balance;
  String? remark;
  String createTime;
  String? updateTime;

  Asset({
    required this.assetId,
    required this.userId,
    required this.assetType,
    required this.name,
    this.bankName,
    this.cardLastFour,
    required this.balance,
    this.remark,
    required this.createTime,
    this.updateTime,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      assetId: json['assetId'] ?? '',
      userId: json['userId'] ?? '',
      assetType: json['assetType'] ?? 0,
      name: json['name'] ?? '',
      bankName: json['bankName'],
      cardLastFour: json['cardLastFour'],
      balance: (json['balance'] ?? 0).toDouble(),
      remark: json['remark'],
      createTime: json['createTime'] ?? '',
      updateTime: json['updateTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'userId': userId,
      'assetType': assetType,
      'name': name,
      'bankName': bankName,
      'cardLastFour': cardLastFour,
      'balance': balance,
      'remark': remark,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  static const int TYPE_CASH = 1;
  static const int TYPE_SAVINGS_CARD = 2;
  static const int TYPE_CREDIT_CARD = 3;
  static const int TYPE_VIRTUAL = 4;
  static const int TYPE_INVESTMENT = 5;
  static const int TYPE_DEBT = 6;
  static const int TYPE_RECEIVABLE = 7;
  static const int TYPE_CUSTOM = 8;

  bool get isLiability => assetType == TYPE_CREDIT_CARD || assetType == TYPE_DEBT;

  String get displayName {
    if (bankName != null && bankName!.isNotEmpty) {
      if (cardLastFour != null && cardLastFour!.isNotEmpty) {
        return '$bankName($cardLastFour)';
      }
      return bankName!;
    }
    return name;
  }

  static String getTypeName(int type) {
    switch (type) {
      case TYPE_CASH:
        return '现金';
      case TYPE_SAVINGS_CARD:
        return '储蓄卡';
      case TYPE_CREDIT_CARD:
        return '信用卡';
      case TYPE_VIRTUAL:
        return '虚拟账户';
      case TYPE_INVESTMENT:
        return '投资账户';
      case TYPE_DEBT:
        return '负债';
      case TYPE_RECEIVABLE:
        return '债权';
      case TYPE_CUSTOM:
        return '自定义';
      default:
        return '其他';
    }
  }

  Asset copyWith({
    String? assetId,
    String? userId,
    int? assetType,
    String? name,
    String? bankName,
    String? cardLastFour,
    double? balance,
    String? remark,
    String? createTime,
    String? updateTime,
  }) {
    return Asset(
      assetId: assetId ?? this.assetId,
      userId: userId ?? this.userId,
      assetType: assetType ?? this.assetType,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      balance: balance ?? this.balance,
      remark: remark ?? this.remark,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}

class AssetRecord {
  String recordId;
  String assetId;
  String userId;
  int operationType;
  double beforeBalance;
  double afterBalance;
  double changeAmount;
  String? remark;
  String createTime;

  AssetRecord({
    required this.recordId,
    required this.assetId,
    required this.userId,
    required this.operationType,
    required this.beforeBalance,
    required this.afterBalance,
    required this.changeAmount,
    this.remark,
    required this.createTime,
  });

  factory AssetRecord.fromJson(Map<String, dynamic> json) {
    return AssetRecord(
      recordId: json['recordId'] ?? '',
      assetId: json['assetId'] ?? '',
      userId: json['userId'] ?? '',
      operationType: json['operationType'] ?? 0,
      beforeBalance: (json['beforeBalance'] ?? 0).toDouble(),
      afterBalance: (json['afterBalance'] ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] ?? 0).toDouble(),
      remark: json['remark'],
      createTime: json['createTime'] ?? '',
    );
  }

  static const int OP_MANUAL_ADJUST = 1;
  static const int OP_EXPENSE = 2;
  static const int OP_INCOME = 3;
  static const int OP_TRANSFER_IN = 4;
  static const int OP_TRANSFER_OUT = 5;

  static String getOperationName(int type) {
    switch (type) {
      case OP_MANUAL_ADJUST:
        return '手动调整余额';
      case OP_EXPENSE:
        return '支出';
      case OP_INCOME:
        return '收入';
      case OP_TRANSFER_IN:
        return '转入';
      case OP_TRANSFER_OUT:
        return '转出';
      default:
        return '其他';
    }
  }
}

class AssetOverview {
  double totalAsset;
  double totalLiability;
  double netAsset;

  AssetOverview({
    required this.totalAsset,
    required this.totalLiability,
    required this.netAsset,
  });

  factory AssetOverview.fromJson(Map<String, dynamic> json) {
    return AssetOverview(
      totalAsset: (json['totalAsset'] ?? 0).toDouble(),
      totalLiability: (json['totalLiability'] ?? 0).toDouble(),
      netAsset: (json['netAsset'] ?? 0).toDouble(),
    );
  }
}
