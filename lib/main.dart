import 'package:flutter/material.dart';
import 'package:journal_windows/core/app.dart';
import 'package:journal_windows/core/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入
  await Injection.init();
  
  // 初始化应用
  await initApp(Env.prod);
  
  // 运行应用
  runApp(buildApp());
}