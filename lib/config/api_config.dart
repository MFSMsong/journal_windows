/// API配置
class ApiConfig {
  /// 生产环境地址
  static const String prodBaseUrl = "https://journal.uuorb.com/api";
  
  /// 本地开发地址
  static const String localBaseUrl = "http://localhost:5666/api";
  
  /// 当前使用的地址
  static const String baseUrl = localBaseUrl;

  // ============ 用户相关接口 ============
  
  /// 发送短信验证码
  static String sendSmsCode() => "$baseUrl/user/login/smsCode";
  
  /// 发送邮箱验证码
  static String sendEmailCode() => "$baseUrl/user/login/emailCode";
  
  /// 登录（手机号/邮箱）
  static String login() => "$baseUrl/user/login";
  
  /// 获取用户信息
  static String getUserProfile() => "$baseUrl/user/profile/me";
  
  /// 更新用户信息
  static String updateUserInfo() => "$baseUrl/user";
  
  /// 删除用户账户
  static String deleteUser() => "$baseUrl/user/delete";

  // ============ 腾讯云相关接口 ============

  /// 获取 COS 临时凭证
  static String getCosCredential() => "$baseUrl/tencent/cos/credential";

  // ============ 账单相关接口 ============
  
  /// 获取账单列表
  static String getExpenseList(String activityId) => "$baseUrl/expense/list/$activityId";
  
  /// 创建账单
  static String createExpense() => "$baseUrl/expense";
  
  /// 创建账单（当前账本）
  static String createExpenseCurrent() => "$baseUrl/expense/current";
  
  /// 更新账单
  static String updateExpense() => "$baseUrl/expense";
  
  /// 删除账单
  static String deleteExpense(String expenseId, String activityId) => 
      "$baseUrl/expense/$expenseId/$activityId";

  // ============ 账本相关接口 ============
  
  /// 获取我的账本列表
  static String getActivityList() => "$baseUrl/activity/list";
  
  /// 获取加入的账本列表
  static String getJoinedActivityList() => "$baseUrl/activity/list/joined";
  
  /// 获取当前账本
  static String getCurrentActivity() => "$baseUrl/activity/current";
  
  /// 搜索账本
  static String searchActivity(String activityId) => "$baseUrl/activity/search/$activityId";
  
  /// 创建账本
  static String createActivity() => "$baseUrl/activity";
  
  /// 更新账本
  static String updateActivity() => "$baseUrl/activity";
  
  /// 删除账本
  static String deleteActivity(String activityId) => "$baseUrl/activity/$activityId";
  
  /// 加入账本
  static String joinActivity(String activityId) => "$baseUrl/activity/join/$activityId";
  
  /// 退出账本
  static String exitActivity(String activityId) => "$baseUrl/activity/exit/$activityId";
  
  /// 判断是否为账本所有者
  static String isActivityOwner() => "$baseUrl/activity/isOwner";

  // ============ 图表统计接口 ============
  
  /// 获取周支出统计
  static String getChartsWeekly(String activityId) => "$baseUrl/charts/weekly/$activityId";
  
  /// 获取周收入统计
  static String getChartsWeeklyIncome(String activityId) => 
      "$baseUrl/charts/weekly/income/$activityId";
  
  /// 获取分类统计
  static String getChartsWeeklyType(String activityId) => 
      "$baseUrl/charts/weekly/type/$activityId";
  
  /// 导出Excel
  static String exportCharts(String activityId) => "$baseUrl/charts/export/$activityId";

  // ============ 资产管理接口 ============
  
  /// 获取资产概览
  static String getAssetOverview() => "$baseUrl/asset/overview";
  
  /// 获取资产列表
  static String getAssetList() => "$baseUrl/asset/list";
  
  /// 获取资产详情
  static String getAssetDetail(String assetId) => "$baseUrl/asset/$assetId";
  
  /// 创建资产
  static String createAsset() => "$baseUrl/asset";
  
  /// 更新资产
  static String updateAsset(String assetId) => "$baseUrl/asset/$assetId";
  
  /// 删除资产
  static String deleteAsset(String assetId) => "$baseUrl/asset/$assetId";
  
  /// 调整资产余额
  static String adjustAssetBalance(String assetId) => "$baseUrl/asset/$assetId/adjust";
  
  /// 获取资产变动记录
  static String getAssetRecords(String assetId) => "$baseUrl/asset/$assetId/records";
}
