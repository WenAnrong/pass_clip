import 'package:flutter/material.dart';
import 'routers/index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '账号密码管理',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        brightness: Brightness.light,
      ),
      initialRoute: '/',
      routes: AppRouter.routes,
    );
  }
}

