import 'package:get/get.dart';
import 'package:journal_windows/services/user_service.dart';
import 'package:journal_windows/services/activity_service.dart';
import 'package:journal_windows/services/expense_service.dart';
import 'package:journal_windows/services/charts_service.dart';
import 'package:journal_windows/services/tencent_service.dart';
import 'package:journal_windows/services/asset_service.dart';
import 'package:journal_windows/services/websocket_service.dart';

/// 依赖注入初始化
class Injection {
  static Future<void> init() async {
    // 注册服务
    Get.put(UserService());
    Get.put(ActivityService());
    Get.put(ExpenseService());
    Get.put(ChartsService());
    Get.put(AssetService());
    Get.put(WebSocketService());
    TencentService.init();
  }
}
