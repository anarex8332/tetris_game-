import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/tetromino.dart';
import '../models/tetromino_type.dart';
import '../theme/ussr_colors.dart';

/// Данные для анимации Hard Drop: трейл + вспышка.
class HardDropAnimationData {
  final Tetromino piece;
  final int startY;
  final int endY;
  final double progress;

  HardDropAnimationData({
    required this.piece,
    required this.startY,
    required this.endY,
    required this.progress,
  });
}

/// Отрисовка игрового поля в советском стиле.
class BoardPainter extends CustomPainter {
  final GameBoard gameBoard;
  final Tetromino? activePiece;
  final bool showGhost;
  final double cellSize;
  final HardDropAnimationData? hardDropData;

  BoardPainter({
    required this.gameBoard,
    this.activePiece,
    this.showGhost = true,
    this.cellSize = 30.0,
    this.hardDropData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawGrid(canvas);
    _drawLockedBlocks(canvas);

    if (hardDropData != null) {
      _drawHardDropTrail(canvas, hardDropData!);
    }
    if (showGhost && activePiece != null) {
      _drawGhostPiece(canvas, activePiece!);
    }
    if (activePiece != null) {
      _drawPiece(canvas, activePiece!);
    }
    if (hardDropData != null) {
      _drawHardDropFlash(canvas, hardDropData!);
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.gameBoard != gameBoard ||
        oldDelegate.activePiece != activePiece ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.hardDropData != hardDropData;
  }

  // ========== ФОН (бежевый, "старая бумага") ==========

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = USSRColors.backgroundBeige;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  }

  // ========== СЕТКА ==========

  void _drawGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = USSRColors.darkGray.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int col = 0; col <= GameBoard.width; col++) {
      final x = col * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, GameBoard.height * cellSize), gridPaint);
    }
    for (int row = 0; row <= GameBoard.height; row++) {
      final y = row * cellSize;
      canvas.drawLine(Offset(0, y), Offset(GameBoard.width * cellSize, y), gridPaint);
    }
  }

  // ========== ЗАСТЫВШИЕ БЛОКИ (USSR цвета) ==========

  void _drawLockedBlocks(Canvas canvas) {
    for (int row = 0; row < GameBoard.height; row++) {
      for (int col = 0; col < GameBoard.width; col++) {
        final value = gameBoard.board[row][col];
        if (value == 0) continue;
        final type = TetrominoType.fromValue(value);
        if (type == null) continue;
        _drawBlock(
          canvas, col.toDouble(), row.toDouble(),
          getUssrColor(type),
          bright: true,
        );
      }
    }
  }

  // ========== АКТИВНАЯ ФИГУРА (USSR цвета) ==========

  void _drawPiece(Canvas canvas, Tetromino piece) {
    final shape = piece.shape;
    final color = getUssrColor(piece.type);
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) continue;
        _drawBlock(canvas, (piece.x + col).toDouble(), (piece.y + row).toDouble(), color, bright: true);
      }
    }
  }

  // ========== GHOST PIECE (пунктирная рамка) ==========

  void _drawGhostPiece(Canvas canvas, Tetromino piece) {
    final ghostY = gameBoard.getGhostY(piece);
    final shape = piece.shape;
    final color = getUssrColor(piece.type).withValues(alpha: 0.3);

    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) continue;
        final gy = ghostY + row;
        if (gy < 0) continue;

        final rect = Rect.fromLTWH(
          (piece.x + col) * cellSize + 1,
          gy * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

        // Пунктирная рамка
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final path = Path()..addRRect(rrect);
        canvas.drawPath(_dashPath(path, 3, 3), paint);
      }
    }
  }

  Path _dashPath(Path source, double dashLength, double gapLength) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        dest.addPath(metric.extractPath(distance, next.clamp(0, metric.length)), Offset.zero);
        distance = next + gapLength;
      }
    }
    return dest;
  }

  // ========== HARD DROP ТРЕЙЛ ==========

  void _drawHardDropTrail(Canvas canvas, HardDropAnimationData data) {
    final shape = data.piece.shape;
    final color = getUssrColor(data.piece.type);
    final progress = data.progress;
    final trailLength = (data.endY - data.startY).abs();

    // Сразу исчезаем при progress > 0.5 (анимация всего 150ms)
    if (progress > 0.5) return;

    final maxSteps = trailLength.clamp(0, 3);
    for (int step = 1; step <= maxSteps; step++) {
      final t = step / (maxSteps + 1);
      // Быстрое затухание: alpha уменьшается с progress
      final baseAlpha = 0.25 * (1.0 - progress);
      final alpha = (baseAlpha * t).clamp(0.02, 0.25);
      final trailColor = color.withValues(alpha: alpha);
      final rowOffset = (t * trailLength).round();

      for (int row = 0; row < shape.length; row++) {
        for (int col = 0; col < shape[row].length; col++) {
          if (shape[row][col] == 0) continue;
          final gy = data.startY + row + rowOffset;
          if (gy < 0 || gy >= GameBoard.height) continue;
          _drawBlock(canvas, (data.piece.x + col).toDouble(), gy.toDouble(), trailColor, bright: false);
        }
      }
    }

  }

  // ========== HARD DROP ВСПЫШКА ==========

  void _drawHardDropFlash(Canvas canvas, HardDropAnimationData data) {
    final progress = data.progress;
    final flashAlpha = (0.4 * (1 - progress)).clamp(0.0, 0.4);
    if (flashAlpha < 0.01) return;

    final shape = data.piece.shape;
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) continue;
        final bx = (data.piece.x + col).toDouble();
        final by = (data.endY + row).toDouble();
        // Белая вспышка
        final rect = Rect.fromLTWH(bx * cellSize + 1, by * cellSize + 1, cellSize - 2, cellSize - 2);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        final flashPaint = Paint()..color = Colors.white.withValues(alpha: flashAlpha);
        canvas.drawRRect(rrect, flashPaint);
      }
    }
  }

  // ========== БЛОК (с объёмом) ==========

  void _drawBlock(Canvas canvas, double x, double y, Color color, {bool bright = true}) {
    final rect = Rect.fromLTWH(x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    final fillPaint = Paint()..color = color;
    canvas.drawRRect(rrect, fillPaint);

    if (bright) {
      // Блик сверху-слева
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(rrect, highlightPaint);

      final innerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * cellSize + 3, y * cellSize + 3, cellSize - 6, (cellSize - 6) / 2),
        const Radius.circular(2),
      );
      final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
      canvas.drawRRect(innerRect, shinePaint);
    }

    // Чёрная тень снизу-справа
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2),
      const Radius.circular(3),
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(shadowRect, shadowPaint);
  }
}