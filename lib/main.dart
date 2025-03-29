import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 300),
    center: true,
    title: 'Tray App Example',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TrayApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TrayApp extends StatefulWidget {
  const TrayApp({super.key});
  @override
  State<TrayApp> createState() => _TrayAppState();
}

class _TrayAppState extends State<TrayApp> {
  final SystemTray _systemTray = SystemTray();

  @override
  void initState() {
    super.initState();
    _initSystemTray();
  }

  Future<void> _initSystemTray() async {
    // 1. 아이콘 경로 설정 (assets 확인)
    String path = 'assets/app_icon.ico';
    if (!await File(path).exists()) {
      debugPrint("아이콘 파일 없음: $path");
      // 기본 아이콘으로 대체하거나 에러 처리
    }

    // 2. 시스템 트레이 초기화 (간단하게 시작)
    await _systemTray.initSystemTray(iconPath: path);

    // 3. 추가 속성 설정
    _systemTray.setTitle("Tray App");
    _systemTray.setToolTip("시스템 트레이 앱");

    // 4. 메뉴 구성
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Open',
        onClicked: (_) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (_) async {
          await _systemTray.destroy();
          exit(0);
        },
      ),
      MenuItemLabel(
        label: 'FindWindow',
        onClicked: (_) async {
          await bringWindowToFrontViaFindWindow();
        },
      ),
    ]);

    // 5. 구성된 메뉴를 컨텍스트 메뉴로 설정
    await _systemTray.setContextMenu(menu);

    // 6. 이벤트 핸들러 등록 (플랫폼별 처리)
    _systemTray.registerSystemTrayEventHandler((eventName) async {
      debugPrint("시스템 트레이 이벤트: $eventName");
      if (eventName == kSystemTrayEventClick) {
        if (Platform.isWindows) {
          await windowManager.show();
          await windowManager.focus();
        } else {
          await _systemTray.popUpContextMenu();
        }
      } else if (eventName == kSystemTrayEventRightClick) {
        if (Platform.isWindows) {
          await _systemTray.popUpContextMenu();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      }
    });
  }

  Future<void> _sendToTray() async {
    await windowManager.hide();
  }

  static const platform = MethodChannel('com.example.tray_channel');

  Future<void> bringWindowToFrontViaFindWindow() async {
    try {
      final bool success = await platform.invokeMethod('bring_to_front');
      debugPrint("FindWindow 실행 결과: $success");
    } on PlatformException catch (e) {
      debugPrint("에러: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Tray Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: _sendToTray,
          child: const Text('트레이로 보내기'),
        ),
      ),
    );
  }
}
