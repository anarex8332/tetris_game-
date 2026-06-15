import 'package:flutter/material.dart';
import '../models/game_result.dart';
import '../models/score_storage.dart';
import 'main_menu_screen.dart';

/// Экран Game Over с топ-5 результатами.
class GameOverScreen extends StatefulWidget {
  final GameResult currentResult;

  const GameOverScreen({super.key, required this.currentResult});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<GameResult> _topScores = [];
  bool _isNewRecord = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadScores();
  }

  Future<void> _loadScores() async {
    _topScores = await ScoreStorage.saveResult(widget.currentResult);
    _isNewRecord = _topScores.isNotEmpty &&
        _topScores.first.score == widget.currentResult.score;
    if (mounted) {
      setState(() => _loaded = true);
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _goToMenu() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      (route) => false,
    );
  }

  void _restart() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    const cream = Color(0xFFFFF8E1);
    const darkRed = Color(0xFF8B0000);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC41E3A), Color(0xFF4A0000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loaded
              ? FadeTransition(
                  opacity: _animController,
                  child: _buildContent(gold, cream, darkRed),
                )
              : const Center(
                  child: CircularProgressIndicator(color: gold),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(Color gold, Color cream, Color darkRed) {
    return Column(
      children: [
        const Spacer(flex: 1),

        // GAME OVER заголовок
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF4500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'GAME OVER',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: gold.withValues(alpha: 0.6),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // NEW RECORD
        if (_isNewRecord)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold, width: 1),
            ),
            child: Text(
              'НОВЫЙ РЕКОРД!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: gold,
              ),
            ),
          ),
        const SizedBox(height: 6),

        // Текущий результат
        _buildResultCard(widget.currentResult, gold, cream, isHighlighted: _isNewRecord),

        const SizedBox(height: 20),

        // Топ-5
        Text(
          'ТОП-5',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            color: cream.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ListView.separated(
              itemCount: _topScores.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final result = _topScores[index];
                final isCurrent = result.score == widget.currentResult.score &&
                    result.date == widget.currentResult.date;
                return _buildTopScoreRow(index + 1, result, gold, cream, darkRed, isCurrent);
              },
            ),
          ),
        ),

        // Кнопки
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: darkRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ЗАНОВО',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _goToMenu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: cream,
                      side: BorderSide(color: cream, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'МЕНЮ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontSize: 16,
                        color: cream,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildResultCard(
    GameResult result,
    Color gold,
    Color cream, {
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? gold.withValues(alpha: 0.15)
            : cream.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? gold : cream.withValues(alpha: 0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('СЧЁТ', '${result.score}', gold),
          _buildStat('УРОВЕНЬ', '${result.level}', cream),
          _buildStat('ЛИНИИ', '${result.lines}', cream),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: color.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTopScoreRow(
    int rank,
    GameResult result,
    Color gold,
    Color cream,
    Color darkRed,
    bool isCurrent,
  ) {
    final rankColors = [
      const Color(0xFFFFD700), // 1st gold
      const Color(0xFFC0C0C0), // 2nd silver
      const Color(0xFFCD7F32), // 3rd bronze
    ];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : cream.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? gold.withValues(alpha: 0.15) : cream.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: isCurrent
            ? Border.all(color: gold, width: 1)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${result.score}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrent ? gold : cream,
              ),
            ),
          ),
          Text(
            'Ур. ${result.level}',
            style: TextStyle(
              fontSize: 12,
              color: cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${result.lines}',
            style: TextStyle(
              fontSize: 12,
              color: cream.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}