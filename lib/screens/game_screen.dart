import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/board.dart';
import '../models/game_controller.dart';
import '../models/game_result.dart';
import '../models/tetromino_type.dart';
import '../painters/board_painter.dart';
import '../theme/ussr_colors.dart';
import 'game_over_screen.dart';

/// Главный экран игры (советский стиль).
/// Управление: экранные кнопки + жесты, как в официальном мобильном Tetris.
class GameScreen extends StatefulWidget {
  final GameController controller;

  const GameScreen({super.key, required this.controller});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late Ticker _ticker;

  // ---- DAS / ARR для кнопок Left/Right ----
  Timer? _dasTimer;
  Timer? _arrTimer;
  bool _leftHeld = false;
  bool _rightHeld = false;
  static const int dasDelay = 150;
  static const int arrInterval = 30;

  // ---- Жесты ----
  double _horizontalDragAccum = 0;
  double _verticalDragStartY = 0;
  bool _swipeHandled = false;
  static const double swipeThreshold = 50.0;
  static const double horizontalThreshold = 30.0;

  // ---- Hard Drop анимация ----
  late AnimationController _hardDropController;
  HardDropAnimationData? _hardDropData;

  // ---- TETRIS! Animation Controllers ----
  late AnimationController _tetrisTextController;
  late AnimationController _tetrisFlashController;
  late AnimationController _tetrisParticlesController;
  late AnimationController _tetrisShakeController;
  late AnimationController _tetrisBonusController;
  bool _tetrisActive = false;

  // ---- Line Clear Animation (1-3 lines) ----
  late AnimationController _clearFlashController;
  bool _clearFlashActive = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
    _ticker = createTicker(_onTick)..start();

    _hardDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _hardDropController.addListener(() {
      if (_hardDropData != null) {
        _hardDropData = HardDropAnimationData(
          piece: _hardDropData!.piece,
          startY: _hardDropData!.startY,
          endY: _hardDropData!.endY,
          progress: _hardDropController.value,
        );
        if (mounted) setState(() {});
      }
    });
    _hardDropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) _hardDropData = null;
    });

    _initTetrisAnimations();
  }

  void _initTetrisAnimations() {
    _tetrisTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tetrisFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _tetrisParticlesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tetrisShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tetrisBonusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _clearFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _clearFlashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          _clearFlashActive = false;
          setState(() {});
        }
      }
    });
  }

  void _startTetrisAnimation() {
    _tetrisActive = true;
    _tetrisTextController.reset();
    _tetrisFlashController.reset();
    _tetrisParticlesController.reset();
    _tetrisShakeController.reset();
    _tetrisBonusController.reset();
    _tetrisTextController.forward();
    _tetrisFlashController.forward();
    _tetrisParticlesController.forward();
    _tetrisShakeController.forward();
    _tetrisBonusController.forward();
    setState(() {});

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _tetrisActive = false;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    _ticker.dispose();
    _hardDropController.dispose();
    _tetrisTextController.dispose();
    _tetrisFlashController.dispose();
    _tetrisParticlesController.dispose();
    _tetrisShakeController.dispose();
    _tetrisBonusController.dispose();
    _clearFlashController.dispose();
    _cancelButtonTimers();
    super.dispose();
  }

  void _cancelButtonTimers() {
    _dasTimer?.cancel();
    _arrTimer?.cancel();
    _dasTimer = null;
    _arrTimer = null;
    _leftHeld = false;
    _rightHeld = false;
  }

  void _onTick(Duration elapsed) => widget.controller.tick();

  bool _showGameOverOverlay = false;

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        if (widget.controller.tetrisTriggered && !_tetrisActive) {
          _startTetrisAnimation();
        }
        if (widget.controller.lastClearedCount > 0 && !_clearFlashActive && !_tetrisActive) {
          _clearFlashActive = true;
          widget.controller.resetLastClearedCount();
          _clearFlashController.reset();
          _clearFlashController.forward();
        }
      });
      if (widget.controller.state == GameState.gameOver && !_showGameOverOverlay) {
        _showGameOverOverlay = true;
        _scheduleGameOverExit();
      }
    }
  }

  void _scheduleGameOverExit() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _saveHighScoreAndExit();
    });
  }

  Future<void> _saveHighScoreAndExit() async {
    final score = widget.controller.score;
    final level = widget.controller.level;
    final lines = widget.controller.linesCleared;

    if (mounted) {
      _showGameOverOverlay = false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameOverScreen(
            currentResult: GameResult(
              score: score,
              level: level,
              lines: lines,
              date: DateTime.now(),
            ),
          ),
        ),
      );
    }
  }

  // ========== УПРАВЛЕНИЕ: КНОПКИ ==========

  void _onLeftDown() {
    if (_leftHeld || _rightHeld) return;
    _leftHeld = true;
    widget.controller.moveLeft();
    _dasTimer = Timer(const Duration(milliseconds: dasDelay), () {
      _arrTimer = Timer.periodic(const Duration(milliseconds: arrInterval), (_) {
        widget.controller.moveLeft();
      });
    });
  }

  void _onRightDown() {
    if (_leftHeld || _rightHeld) return;
    _rightHeld = true;
    widget.controller.moveRight();
    _dasTimer = Timer(const Duration(milliseconds: dasDelay), () {
      _arrTimer = Timer.periodic(const Duration(milliseconds: arrInterval), (_) {
        widget.controller.moveRight();
      });
    });
  }

  void _onButtonUp() {
    _cancelButtonTimers();
  }

  // ========== УПРАВЛЕНИЕ: ЖЕСТЫ ==========

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragAccum += details.delta.dx;
    while (_horizontalDragAccum.abs() >= horizontalThreshold) {
      if (_horizontalDragAccum > 0) {
        widget.controller.moveRight();
        _horizontalDragAccum -= horizontalThreshold;
      } else {
        widget.controller.moveLeft();
        _horizontalDragAccum += horizontalThreshold;
      }
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _verticalDragStartY = details.localPosition.dy;
    _swipeHandled = false;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_swipeHandled) return;
    final dy = details.localPosition.dy - _verticalDragStartY;

    if (dy.abs() >= swipeThreshold) {
      _swipeHandled = true;
      if (dy > 0) {
        // Свайп вниз → hard drop
        _triggerHardDrop(widget.controller);
      } else {
        // Свайп вверх → hold
        widget.controller.hold();
      }
    }
  }

  void _triggerHardDrop(GameController ctrl) {
    final piece = ctrl.currentPiece;
    if (piece == null) return;
    final startY = piece.y;
    final ghostY = ctrl.board.getGhostY(piece);
    final dropPiece = piece.copyWith();
    ctrl.hardDrop();
    _hardDropController.reset();
    _hardDropData = HardDropAnimationData(
      piece: dropPiece, startY: startY, endY: ghostY, progress: 0.0,
    );
    _hardDropController.forward();
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final cellSize = _calculateCellSize(context);

    return Scaffold(
      backgroundColor: USSRColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(ctrl),
            Expanded(
              child: GestureDetector(
                onTap: () => ctrl.rotate(),
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                child: _buildGameBoardWithEffects(ctrl, cellSize),
              ),
            ),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoardWithEffects(GameController ctrl, double cellSize) {
    final boardWidth = GameBoard.width * cellSize;
    final boardHeight = GameBoard.height * cellSize;

    Widget board = Container(
      decoration: BoxDecoration(
        border: Border.all(color: USSRColors.darkRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: USSRColors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(boardWidth, boardHeight),
            painter: BoardPainter(
              gameBoard: ctrl.board,
              activePiece: ctrl.currentPiece,
              showGhost: ctrl.state == GameState.playing,
              cellSize: cellSize,
              hardDropData: _hardDropData,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinePainter(),
              ),
            ),
          ),
        ],
      ),
    );

    // Screen Shake
    if (_tetrisActive) {
      board = AnimatedBuilder(
        animation: _tetrisShakeController,
        builder: (context, child) {
          final shakeAmount = 4.0 * (1.0 - _tetrisShakeController.value);
          final dx = (Random().nextDouble() - 0.5) * 2 * shakeAmount;
          final dy = (Random().nextDouble() - 0.5) * 2 * shakeAmount;
          return Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          );
        },
        child: board,
      );
    }

    return SizedBox(
      width: boardWidth,
      height: boardHeight,
      child: Stack(
        children: [
          board,

          // Flash overlay
          if (_tetrisActive)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _tetrisFlashController,
                builder: (context, child) {
                  final progress = _tetrisFlashController.value;
                  double opacity = 0.0;
                  if (progress < 0.25) {
                    opacity = (progress / 0.25) * 0.8;
                  } else if (progress < 0.40) {
                    opacity = 0.8 * (1.0 - (progress - 0.25) / 0.15);
                  } else if (progress < 0.60) {
                    opacity = ((progress - 0.40) / 0.20) * 0.6;
                  } else if (progress < 0.75) {
                    opacity = 0.6 * (1.0 - (progress - 0.60) / 0.15);
                  } else if (progress < 0.90) {
                    opacity = ((progress - 0.75) / 0.15) * 0.4;
                  } else {
                    opacity = 0.4 * (1.0 - (progress - 0.90) / 0.10);
                  }
                  return Container(
                    color: const Color(0xFFFFD700).withValues(alpha: opacity),
                  );
                },
              ),
            ),

          // Line clear flash (1-3 lines)
          if (_clearFlashActive)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _clearFlashController,
                builder: (context, child) {
                  final progress = _clearFlashController.value;
                  final opacity = (1.0 - progress).clamp(0.0, 0.6);
                  return Container(
                    color: Colors.white.withValues(alpha: opacity),
                  );
                },
              ),
            ),

          // Particles overlay
          if (_tetrisActive)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _tetrisParticlesController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _TetrisParticlesPainter(
                        progress: _tetrisParticlesController.value,
                        boardWidth: boardWidth,
                        boardHeight: boardHeight,
                      ),
                    );
                  },
                ),
              ),
            ),

          // TETRIS! text
          if (_tetrisActive)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _tetrisTextController,
                builder: (context, child) {
                  final progress = _tetrisTextController.value;
                  double scale;
                  if (progress < 0.4) {
                    scale = progress / 0.4 * 1.5;
                  } else {
                    scale = 1.5 - (progress - 0.4) / 0.6 * 0.5;
                  }
                  double rotation;
                  if (progress < 0.3) {
                    rotation = -10.0 * (1.0 - progress / 0.3);
                  } else if (progress < 0.7) {
                    rotation = 0.0 + 5.0 * ((progress - 0.3) / 0.4);
                  } else {
                    rotation = 5.0 * (1.0 - (progress - 0.7) / 0.3);
                  }

                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: rotation * (pi / 180.0),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFF4500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'ТЕТРИС!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: boardWidth / 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                                  blurRadius: 20,
                                ),
                                Shadow(
                                  color: const Color(0xFFFF4500).withValues(alpha: 0.5),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bonus score text
          if (_tetrisActive)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _tetrisBonusController,
                builder: (context, child) {
                  final progress = _tetrisBonusController.value;
                  final bonus = 1200 * widget.controller.level;
                  final offset = -progress * 40.0;
                  final opacity = 1.0 - progress;
                  final scale = progress < 0.2 ? progress / 0.2 : 1.2 - (progress - 0.2) / 0.8 * 0.2;

                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: const Offset(0, -30),
                          child: Transform.scale(
                            scale: scale,
                            child: Text(
                              '+$bonus',
                              style: TextStyle(
                                fontSize: boardWidth / 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ========== USSR TOP BAR ==========

  Widget _buildTopBar(GameController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [USSRColors.panelRed, USSRColors.darkRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: USSRColors.darkRed, width: 3),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ctrl.hold(),
            child: _buildMiniPreviewBox('ЗАПАС', ctrl.holdPiece),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('СЧЁТ', '${ctrl.score}'),
                _buildStatColumn('УРОВЕНЬ', '${ctrl.level}'),
                _buildStatColumn('ЛИНИИ', '${ctrl.linesCleared}'),
              ],
            ),
          ),
          if (ctrl.getNextPieces().isNotEmpty)
            _buildMiniPreviewBox('СЛЕД', ctrl.getNextPieces().first),
          const SizedBox(width: 8),
          if (ctrl.state == GameState.paused)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Text(
                'ПАУЗА',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              ctrl.state == GameState.paused ? Icons.play_arrow : Icons.pause,
              color: Colors.white70,
              size: 24,
            ),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
            onPressed: ctrl.togglePause,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPreviewBox(String label, TetrominoType? type) {
    final Color bgColor = type != null
        ? getUssrColor(type).withValues(alpha: 0.4)
        : USSRColors.black;
    final Color borderColor = type != null
        ? getUssrColor(type).withValues(alpha: 0.9)
        : USSRColors.red;

    return Column(
      key: ValueKey('${label}_box_${type?.label ?? "empty"}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: USSRColors.cream,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 60, height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: type != null
              ? Center(
                  child: _MiniPiecePreview(
                    key: ValueKey('preview_${label}_${type.label}'),
                    type: type,
                    cellSize: 8.0,
                  ),
                )
              : Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: USSRColors.cream.withValues(alpha: 0.5),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: USSRColors.cream,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: USSRColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ========== КНОПКИ УПРАВЛЕНИЯ ==========

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [USSRColors.darkRed, Color(0xFF4A0000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(color: USSRColors.red, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildButton(
              label: '◄',
              onDown: _onLeftDown,
              onUp: _onButtonUp,
            ),
            _buildButton(
              label: '►',
              onDown: _onRightDown,
              onUp: _onButtonUp,
            ),
            _buildButton(
              label: '↻',
              onTap: () => widget.controller.rotate(),
            ),
            _buildButton(
              label: '⬇',
              onTap: () => _triggerHardDrop(widget.controller),
            ),
            _buildButton(
              label: 'ЗАПАС',
              onTap: () => widget.controller.hold(),
              isText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    VoidCallback? onTap,
    VoidCallback? onDown,
    VoidCallback? onUp,
    bool isText = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onDown != null ? (_) => onDown() : null,
      onTapUp: onUp != null ? (_) => onUp() : null,
      onTapCancel: onUp,
      child: Container(
        width: isText ? 72 : 56,
        height: 52,
        decoration: BoxDecoration(
          color: USSRColors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: USSRColors.gold.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isText ? 12 : 22,
              fontWeight: FontWeight.bold,
              color: USSRColors.cream,
              letterSpacing: isText ? 1 : 0,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateCellSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight - 96 - padding.top - padding.bottom - 80;
    final availableWidth = screenWidth - 8;
    final heightBased = availableHeight / GameBoard.height;
    final widthBased = availableWidth / GameBoard.width;
    return (heightBased < widthBased ? heightBased : widthBased).floorToDouble().clamp(16.0, 50.0);
  }
}

// ========== SCANLINE OVERLAY ==========

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.05);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========== TETRIS PARTICLES PAINTER ==========

class _TetrisParticlesPainter extends CustomPainter {
  final double progress;
  final double boardWidth;
  final double boardHeight;

  _TetrisParticlesPainter({
    required this.progress,
    required this.boardWidth,
    required this.boardHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final colors = [const Color(0xFFFFD700), const Color(0xFFFF4500), const Color(0xFFFFFFFF)];
    final centerX = boardWidth / 2;
    final centerY = boardHeight / 2;

    for (int i = 0; i < 25; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 40.0 + random.nextDouble() * 80.0;
      final distance = speed * progress;
      final x = centerX + cos(angle) * distance;
      final y = centerY + sin(angle) * distance;
      final size = 2.0 + random.nextDouble() * 4.0;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final color = colors[i % 3].withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), size, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TetrisParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ========== МИНИ-ПРЕВЬЮ ФИГУРЫ ==========

class _MiniPiecePreview extends StatelessWidget {
  final TetrominoType type;
  final double cellSize;

  const _MiniPiecePreview({
    super.key,
    required this.type,
    this.cellSize = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final shape = _getShape(type);
    final color = getUssrColor(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: shape.map((row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: row.map((cell) {
            return Container(
              width: cellSize,
              height: cellSize,
              margin: const EdgeInsets.all(0.5),
              decoration: BoxDecoration(
                color: cell == 1 ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  List<List<int>> _getShape(TetrominoType type) {
    switch (type) {
      case TetrominoType.i:
        return [[0,0,0,0],[1,1,1,1],[0,0,0,0],[0,0,0,0]];
      case TetrominoType.j:
        return [[1,0,0],[1,1,1],[0,0,0]];
      case TetrominoType.l:
        return [[0,0,1],[1,1,1],[0,0,0]];
      case TetrominoType.o:
        return [[1,1],[1,1]];
      case TetrominoType.s:
        return [[0,1,1],[1,1,0],[0,0,0]];
      case TetrominoType.t:
        return [[0,1,0],[1,1,1],[0,0,0]];
      case TetrominoType.z:
        return [[1,1,0],[0,1,1],[0,0,0]];
    }
  }
}
