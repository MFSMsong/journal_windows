/// API配置
class ApiConfig {
  /// 生产环境地址
  static const String prodBaseUrl = "https://journal.uuorb.com/api";
  
  /// 本地开发地址
  static const String localBaseUrl = "http://localhost:5666/api";
  
  /// 当前使用的地址
  static const String baseUrl = localBaseUrl;

  // ============ 用户相关接口 ============
  
  /// 发送邮箱验证码（登录）
  static String sendEmailCode() => "$baseUrl/user/login/emailCode";
  
  /// 发送邮箱验证码（注册）
  static String sendRegisterEmailCode() => "$baseUrl/user/register/emailCode";
  
  /// 发送邮箱验证码（修改密码）
  static String sendPasswordEmailCode() => "$baseUrl/user/password/emailCode";
  
  /// 登录（邮箱验证码）
  static String login() => "$baseUrl/user/login";
  
  /// 注册（邮箱+密码）
  static String register() => "$baseUrl/user/register";
  
  /// 密码登录
  static String loginWithPassword() => "$baseUrl/user/login/password";
  
  /// 设置密码
  static String setPassword() => "$baseUrl/user/password/set";
  
  /// 修改密码
  static String updatePassword() => "$baseUrl/user/password/update";
  
  /// 检查是否设置密码
  static String hasPassword() => "$baseUrl/user/hasPassword";
  
  /// 获取用户信息
  static String getUserProfile() => "$baseUrl/user/profile/me";
  
  /// 更新用户信息
  static String updateUserInfo() => "$baseUrl/user";
  
  /// 发送邮箱验证码（删除账户）
  static String sendDeleteAccountEmailCode() => "$baseUrl/user/delete/emailCode";
  
  /// 删除用户账户
  static String deleteUser() => "$baseUrl/user/delete";

  /// 退出登录
  static String logout() => "$baseUrl/user/logout";

  // ============ 腾讯云相关接口 ============

  /// 获取 COS 上传凭证
  static String getCosUploadCredential() => "$baseUrl/tencent/cos/upload-credential";

  /// 获取 COS 预签名URL（私有读）
  static String getCosPresignedUrl() => "$baseUrl/tencent/cos/presigned-url";

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
  
  /// 全局搜索账单
  static String searchExpense(String keyword) => "$baseUrl/expense/search?keyword=${Uri.encodeComponent(keyword)}";

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
  
  /// 获取账本成员列表
  static String getActivityMembers(String activityId) => "$baseUrl/activity/members/$activityId";
  
  /// 设置账本内昵称
  static String updateActivityNickname() => "$baseUrl/activity/nickname";
  
  /// 踢出成员（仅创建者可用）
  static String kickMember(String activityId, String userId) => "$baseUrl/activity/kick/$activityId/$userId";

  // ============ 图表统计接口 ============
  
  /// 获取周支出统计
  static String getChartsWeekly(String activityId) => "$baseUrl/charts/weekly/$activityId";
  
  /// 获取周收入统计
  static String getChartsWeeklyIncome(String activityId) => 
      "$baseUrl/charts/weekly/income/$activityId";
  
  /// 获取分类统计
  static String getChartsWeeklyType(String activityId) => 
      "$baseUrl/charts/weekly/type/$activityId";
  
  /// 获取聚合统计数据（统一接口）
  static String getChartsAggregate(String activityId) => "$baseUrl/charts/aggregate/$activityId";
  
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

  /// 获取资产年度趋势
  static String get getAssetTrend => "$baseUrl/asset/trend";

  // ============ AI相关接口 ============

  /// AI聊天
  static String get aiChat => "$baseUrl/ai/chat";
}
