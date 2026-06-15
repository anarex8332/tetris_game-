import 'tetromino.dart';
import 'tetromino_type.dart';

/// Реализация Wall Kicks по системе SRS (Super Rotation System).
///
/// При повороте фигуры у стены/пола/других блоков проверяются
/// 5 вариантов смещения (kick offsets). Если хотя бы один подходит —
/// фигура смещается и поворачивается.
///
/// Таблицы взяты из официальной SRS-спецификации:
/// https://tetris.wiki/Super_Rotation_System
class WallKicks {
  /// Таблица смещений для J, L, S, T, Z (3×3 фигуры).
  /// Индексы: [fromRotation][toRotation][kickIndex] -> (dx, dy)
  /// where fromRotation и toRotation — 0..3, kickIndex — 0..4
  static const Map<String, List<(int, int)>> _jlstzOffsets = {
    '0>1': [(0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2)],
    '1>0': [(0, 0), (1, 0), (1, 1), (0, -2), (1, -2)],
    '1>2': [(0, 0), (1, 0), (1, 1), (0, -2), (1, -2)],
    '2>1': [(0, 0), (-1, 0), (-1, -1), (0, 2), (-1, 2)],
    '2>3': [(0, 0), (1, 0), (1, -1), (0, 2), (1, 2)],
    '3>2': [(0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2)],
    '3>0': [(0, 0), (-1, 0), (-1, 1), (0, -2), (-1, -2)],
    '0>3': [(0, 0), (1, 0), (1, -1), (0, 2), (1, 2)],
  };

  /// Таблица смещений для I-фигуры (4×4).
  static const Map<String, List<(int, int)>> _iOffsets = {
    '0>1': [(0, 0), (-2, 0), (1, 0), (-2, 1), (1, -2)],
    '1>0': [(0, 0), (2, 0), (-1, 0), (2, -1), (-1, 2)],
    '1>2': [(0, 0), (-1, 0), (2, 0), (-1, -2), (2, 1)],
    '2>1': [(0, 0), (1, 0), (-2, 0), (1, 2), (-2, -1)],
    '2>3': [(0, 0), (2, 0), (-1, 0), (2, -1), (-1, 2)],
    '3>2': [(0, 0), (-2, 0), (1, 0), (-2, 1), (1, -2)],
    '3>0': [(0, 0), (1, 0), (-2, 0), (1, 2), (-2, -1)],
    '0>3': [(0, 0), (-1, 0), (2, 0), (-1, -2), (2, 1)],
  };

  /// Пытается повернуть фигуру [piece] по часовой стрелке,
  /// применяя Wall Kicks. Возвращает новую позицию, если поворот успешен,
  /// иначе возвращает [null].
  ///
  /// [canPlace] — функция проверки размещения (от GameBoard).
  static Tetromino? tryRotateCW(
    Tetromino piece,
    bool Function(Tetromino) canPlace,
  ) {
    final rotated = piece.rotateCW();
    return _tryKick(piece, rotated, canPlace);
  }

  /// Пытается повернуть фигуру [piece] против часовой стрелки,
  /// применяя Wall Kicks. Возвращает новую позицию, если поворот успешен,
  /// иначе возвращает [null].
  static Tetromino? tryRotateCCW(
    Tetromino piece,
    bool Function(Tetromino) canPlace,
  ) {
    final rotated = piece.rotateCCW();
    return _tryKick(piece, rotated, canPlace);
  }

  /// Подбирает подходящее смещение из таблицы.
  static Tetromino? _tryKick(
    Tetromino original,
    Tetromino rotated,
    bool Function(Tetromino) canPlace,
  ) {
    final key = '${original.rotationIndex}>${rotated.rotationIndex}';
    final offsets = original.type == TetrominoType.i
        ? _iOffsets[key]
        : original.type == TetrominoType.o
            ? null // O-фигура не требует kicks
            : _jlstzOffsets[key];

    if (offsets == null) {
      // Без kicks — проверяем базовую позицию
      if (canPlace(rotated)) return rotated;
      return null;
    }

    for (final (dx, dy) in offsets) {
      final kicked = rotated.copyWith(x: rotated.x + dx, y: rotated.y - dy);
      if (canPlace(kicked)) return kicked;
    }

    return null; // Ни один kick не подошёл
  }
}