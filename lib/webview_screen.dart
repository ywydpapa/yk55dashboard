import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  List<String> _urls = [];
  int _interval = 10;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 상단 상태바 및 하단 네비게이션 바 숨기기 (전체화면 모드)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initWebView();
    _loadSettingsAndStart();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // 자바스크립트 실행 허용
      ..addJavaScriptChannel(
        'FlutterChannel', // JS에서 Flutter로 메시지를 보낼 채널 이름
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'double_click') {
            _goToSettings();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // 페이지 로드가 끝나면 더블 클릭 감지 자바스크립트 주입
            _controller.runJavaScript('''
              document.addEventListener('dblclick', function() {
                FlutterChannel.postMessage('double_click');
              });
            ''');
          },
        ),
      );
  }

  Future<void> _loadSettingsAndStart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _urls = prefs.getStringList('urls') ?? [];
      _interval = prefs.getInt('interval') ?? 10;
    });

    if (_urls.isNotEmpty) {
      _loadCurrentUrl();
      _startTimer();
    }
  }

  void _loadCurrentUrl() {
    String url = _urls[_currentIndex];
    // http가 없으면 자동으로 붙여줌
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    _controller.loadRequest(Uri.parse(url));
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _interval), (timer) {
      if (_urls.length == 1) {
        // URL이 1개일 경우 새로고침
        _controller.reload();
      } else {
        // URL이 여러 개일 경우 다음 URL로 이동
        setState(() {
          _currentIndex = (_currentIndex + 1) % _urls.length;
        });
        _loadCurrentUrl();
      }
    });
  }

  void _goToSettings() {
    _timer?.cancel();
    // 전체화면 모드 해제 후 설정 화면으로 이동
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.pushReplacementNamed(context, '/settings');
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 앱 종료 시 전체화면 모드 복구
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // SafeArea를 무시하고 꽉 채우려면 SafeArea를 제거하셔도 됩니다.
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
