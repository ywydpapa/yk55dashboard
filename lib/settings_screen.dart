import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<TextEditingController> _urlControllers = [];
  final TextEditingController _intervalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 기존 설정 불러오기
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? urls = prefs.getStringList('urls');
    int? interval = prefs.getInt('interval');

    if (urls != null && urls.isNotEmpty) {
      for (String url in urls) {
        _urlControllers.add(TextEditingController(text: url));
      }
    } else {
      _urlControllers.add(TextEditingController()); // 기본 입력칸 1개
    }

    if (interval != null) {
      _intervalController.text = interval.toString();
    }
    setState(() {});
  }

  // 설정 저장 및 실행
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 빈 칸 제외하고 URL 리스트 생성
    List<String> urls = _urlControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    int? interval = int.tryParse(_intervalController.text);

    if (urls.isEmpty || interval == null || interval <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 URL과 갱신 주기(초)를 입력해주세요.')),
      );
      return;
    }

    await prefs.setStringList('urls', urls);
    await prefs.setInt('interval', interval);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/webview');
    }
  }

  @override
  void dispose() {
    for (var controller in _urlControllers) {
      controller.dispose();
    }
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('화면 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _urlControllers.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlControllers[index],
                          decoration: InputDecoration(
                            labelText: 'URL ${index + 1}',
                            hintText: 'https://example.com',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _urlControllers[index].dispose();
                            _urlControllers.removeAt(index);
                          });
                        },
                      )
                    ],
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _urlControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('URL 추가'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _intervalController,
              decoration: const InputDecoration(
                labelText: '화면 갱신 주기 (초 단위)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('저장 및 실행', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
