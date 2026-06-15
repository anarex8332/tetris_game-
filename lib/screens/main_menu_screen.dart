import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_controller.dart';
import 'game_screen.dart';

/// Главный экран меню в советской эстетике.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _highScore = prefs.getInt('tetris_high_score') ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading high score: $e');
    }
  }

  Future<void> _startGame() async {
    final controller = GameController();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(controller: controller),
      ),
    );
    await _loadHighScore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC41E3A), Color(0xFF8B0000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Звезда
                const Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                  size: 48,
                ),
                const SizedBox(height: 12),

                // Заголовок "ТЕТРИС"
                Text(
                  'ТЕТРИС',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    color: const Color(0xFFFFF8E1),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'СОВЕТСКАЯ КЛАССИКА',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 6,
                    color: const Color(0xFFFFF8E1).withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(flex: 1),

                // Блок "РЕКОРД"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'РЕКОРД',
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 4,
                              color: Color(0xFFFFF8E1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_highScore',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFF8E1),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Кнопка "ИГРАТЬ"
                SizedBox(
                  width: 240,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF8B0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(
                          color: Color(0xFFFFF8E1),
                          width: 2,
                        ),
                      ),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'ИГРАТЬ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Нижняя плашка
                Text(
                  'СДЕЛАНО В СССР',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 4,
                    color: const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}