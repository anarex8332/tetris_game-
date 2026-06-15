import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Перехват ошибок, чтобы не было белого экрана
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('=== Flutter Error: ${details.exception} ===');
    debugPrint('=== Stack: ${details.stack} ===');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('=== Platform Error: $error ===');
    debugPrint('=== Stack: $stack ===');
    return true;
  };

  runApp(const TetrisApp());
}

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetris',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      home: const MainMenuScreen(),
    );
  }
}
