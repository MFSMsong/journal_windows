import 'package:get/get.dart';
import 'package:journal_windows/pages/login/login_page.dart';
import 'package:journal_windows/pages/login/register_page.dart';
import 'package:journal_windows/pages/main_layout.dart';
import 'package:journal_windows/pages/expense/expense_list_page.dart';
import 'package:journal_windows/pages/activity/activity_list_page.dart';
import 'package:journal_windows/pages/activity/activity_page.dart';
import 'package:journal_windows/pages/charts/charts_page.dart';
import 'package:journal_windows/pages/profile/profile_page.dart';
import 'package:journal_windows/pages/profile/edit_profile_page.dart';

/// 路由管理
abstract class Routers {
  /// 登录页
  static const String LoginPageUrl = '/login';
  
  /// 注册页
  static const String RegisterPageUrl = '/register';
  
  /// 主布局页
  static const String LayoutPageUrl = '/layout';
  
  /// 账单列表页
  static const String ExpenseListPageUrl = '/expense_list';
  
  /// 账本列表页
  static const String ActivityListPageUrl = '/activity_list';
  
  /// 创建/编辑账本页
  static const String ActivityPageUrl = '/activity';
  
  /// 图表统计页
  static const String ChartsPageUrl = '/charts';
  
  /// 个人信息页
  static const String ProfilePageUrl = '/profile';
  
  /// 编辑个人信息页
  static const String EditProfilePageUrl = '/edit_profile';

  /// 路由页面列表
  static final List<GetPage> routePages = [
    GetPage(
      name: LoginPageUrl,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: RegisterPageUrl,
      page: () => const RegisterPage(),
    ),
    GetPage(
      name: LayoutPageUrl,
      page: () => const MainLayout(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: ExpenseListPageUrl,
      page: () => const ExpenseListPage(),
    ),
    GetPage(
      name: ActivityListPageUrl,
      page: () => const ActivityListPage(),
    ),
    GetPage(
      name: ActivityPageUrl,
      page: () => const ActivityPage(),
    ),
    GetPage(
      name: ChartsPageUrl,
      page: () => const ChartsPage(),
    ),
    GetPage(
      name: ProfilePageUrl,
      page: () => const ProfilePage(),
    ),
    GetPage(
      name: EditProfilePageUrl,
      page: () => const EditProfilePage(),
    ),
  ];
}
