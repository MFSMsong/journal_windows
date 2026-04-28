import 'user.dart';
import 'expense.dart';

/// 账本模型
class Activity {
  String activityId;
  String activityName;
  String userId;
  String creatorName;
  String? description;
  double? budget;
  double? remainingBudget;
  double? todayExpense;
  double? weekExpense;
  double? monthExpense;
  double? totalExpense;
  double? totalIncome;
  bool activated;
  String createTime;
  String? updateTime;
  List<Expense>? expenseList;
  List<User>? userList;

  Activity({
    required this.activityId,
    required this.activityName,
    required this.userId,
    required this.creatorName,
    this.description,
    this.budget,
    this.remainingBudget,
    this.todayExpense,
    this.weekExpense,
    this.monthExpense,
    this.totalExpense,
    this.totalIncome,
    required this.activated,
    required this.createTime,
    this.updateTime,
    this.expenseList,
    this.userList,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      activityId: json['activityId'] ?? '',
      activityName: json['activityName'] ?? '',
      userId: json['userId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      description: json['description'],
      budget: json['budget']?.toDouble(),
      remainingBudget: json['remainingBudget']?.toDouble(),
      todayExpense: json['todayExpense']?.toDouble(),
      weekExpense: json['weekExpense']?.toDouble(),
      monthExpense: json['monthExpense']?.toDouble(),
      totalExpense: json['totalExpense']?.toDouble(),
      totalIncome: json['totalIncome']?.toDouble(),
      activated: json['activated'] ?? false,
      createTime: json['createTime'] ?? '',
      updateTime: json['updateTime'],
      expenseList: json['expenseList'] != null
          ? (json['expenseList'] as List).map((e) => Expense.fromJson(e)).toList()
          : null,
      userList: json['userList'] != null
          ? (json['userList'] as List).map((e) => User.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'activityName': activityName,
      'userId': userId,
      'creatorName': creatorName,
      'description': description,
      'budget': budget,
      'remainingBudget': remainingBudget,
      'todayExpense': todayExpense,
      'weekExpense': weekExpense,
      'monthExpense': monthExpense,
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'activated': activated,
      'createTime': createTime,
      'updateTime': updateTime,
      'expenseList': expenseList?.map((e) => e.toJson()).toList(),
      'userList': userList?.map((e) => e.toJson()).toList(),
    };
  }

  /// 是否有预算
  bool get hasBudget => budget != null && budget! > 0;
  
  /// 预算是否超支
  bool get isOverBudget => remainingBudget != null && remainingBudget! < 0;
  
  /// 预算使用百分比
  double get budgetUsagePercent {
    if (budget == null || budget! == 0) return 0;
    if (totalExpense == null) return 0;
    return (totalExpense! / budget! * 100).clamp(0, 100);
  }

  /// 创建空账本
  static Activity empty() {
    return Activity(
      activityId: '',
      activityName: '',
      userId: '',
      creatorName: '',
      activated: false,
      createTime: '',
      expenseList: [],
      userList: [],
    );
  }

  /// 复制并修改
  Activity copyWith({
    String? activityId,
    String? activityName,
    String? userId,
    String? creatorName,
    String? description,
    double? budget,
    double? remainingBudget,
    double? todayExpense,
    double? weekExpense,
    double? monthExpense,
    double? totalExpense,
    double? totalIncome,
    bool? activated,
    String? createTime,
    String? updateTime,
    List<Expense>? expenseList,
    List<User>? userList,
  }) {
    return Activity(
      activityId: activityId ?? this.activityId,
      activityName: activityName ?? this.activityName,
      userId: userId ?? this.userId,
      creatorName: creatorName ?? this.creatorName,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      todayExpense: todayExpense ?? this.todayExpense,
      weekExpense: weekExpense ?? this.weekExpense,
      monthExpense: monthExpense ?? this.monthExpense,
      totalExpense: totalExpense ?? this.totalExpense,
      totalIncome: totalIncome ?? this.totalIncome,
      activated: activated ?? this.activated,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      expenseList: expenseList ?? this.expenseList,
      userList: userList ?? this.userList,
    );
  }

  @override
  String toString() {
    return 'Activity{activityId: $activityId, activityName: $activityName, budget: $budget, remainingBudget: $remainingBudget}';
  }
}
