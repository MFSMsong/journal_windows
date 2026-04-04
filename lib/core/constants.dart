/// 应用常量
class AppConstants {
  /// 应用名称
  static const String appName = '好享记账';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 默认分页大小
  static const int defaultPageSize = 20;

  /// Token过期时间（天）
  static const int tokenExpireDays = 30;
}

/// 消费类型
class ExpenseType {
  static const List<String> expenseTypes = [
    '餐饮',
    '交通',
    '购物',
    '娱乐',
    '医疗',
    '教育',
    '住房',
    '通讯',
    '水电',
    '其他',
  ];

  static const List<String> incomeTypes = [
    '工资',
    '奖金',
    '投资',
    '兼职',
    '红包',
    '其他',
  ];
}

/// 预算类型
class BudgetType {
  static const String monthly = 'monthly';
  static const String weekly = 'weekly';
  static const String daily = 'daily';
  
  static const Map<String, String> budgetTypeLabels = {
    monthly: '月预算',
    weekly: '周预算',
    daily: '日预算',
  };
}
