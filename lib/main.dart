import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'webview_screen.dart';

void main() async {
  // Flutter 바인딩 초기화 (비동기 처리를 위해 필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 저장된 설정 확인
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String>? urls = prefs.getStringList('urls');
  int? interval = prefs.getInt('interval');

  // 설정이 없으면 설정 화면으로, 있으면 웹뷰 화면으로 시작
  String initialRoute = (urls == null || urls.isEmpty || interval == null)
      ? '/settings'
      : '/webview';

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full Screen Web Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: initialRoute,
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/webview': (context) => const WebViewScreen(),
      },
    );
  }
}
