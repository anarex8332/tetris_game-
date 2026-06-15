import 'tetromino_type.dart';

/// Класс, представляющий тетрамино с позицией, типом и состоянием вращения.
class Tetromino {
  final TetrominoType type;
  int x;
  int y;
  int rotationIndex; // 0, 1, 2, 3

  Tetromino({
    required this.type,
    this.x = 3,
    this.y = 0,
    this.rotationIndex = 0,
  });

  /// Копия с возможностью изменить поля.
  Tetromino copyWith({
    int? x,
    int? y,
    int? rotationIndex,
  }) {
    return Tetromino(
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      rotationIndex: rotationIndex ?? this.rotationIndex,
    );
  }

  /// Все матрицы фигур для всех типов.
  /// Индекс: [type.index][rotationIndex] -> список строк, где 1 = блок, 0 = пусто.
  static final Map<TetrominoType, List<List<List<int>>>> _shapes = {
    TetrominoType.i: [
      // 0° (горизонтальная)
      [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ],
      // 90° (вертикальная)
      [
        [0, 0, 1, 0],
        [0, 0, 1, 0],
        [0, 0, 1, 0],
        [0, 0, 1, 0],
      ],
      // 180°
      [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
      ],
      // 270°
      [
        [0, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 0],
      ],
    ],
    TetrominoType.j: [
      [
        [1, 0, 0],
        [1, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 1, 1],
        [0, 1, 0],
        [0, 1, 0],
      ],
      [
        [0, 0, 0],
        [1, 1, 1],
        [0, 0, 1],
      ],
      [
        [0, 1, 0],
        [0, 1, 0],
        [1, 1, 0],
      ],
    ],
    TetrominoType.l: [
      [
        [0, 0, 1],
        [1, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 1, 0],
        [0, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 0, 0],
        [1, 1, 1],
        [1, 0, 0],
      ],
      [
        [1, 1, 0],
        [0, 1, 0],
        [0, 1, 0],
      ],
    ],
    TetrominoType.o: [
      // O фигура одинакова во всех ротациях, но храним 4×4 для единообразия
      [
        [1, 1],
        [1, 1],
      ],
      [
        [1, 1],
        [1, 1],
      ],
      [
        [1, 1],
        [1, 1],
      ],
      [
        [1, 1],
        [1, 1],
      ],
    ],
    TetrominoType.s: [
      [
        [0, 1, 1],
        [1, 1, 0],
        [0, 0, 0],
      ],
      [
        [0, 1, 0],
        [0, 1, 1],
        [0, 0, 1],
      ],
      [
        [0, 0, 0],
        [0, 1, 1],
        [1, 1, 0],
      ],
      [
        [1, 0, 0],
        [1, 1, 0],
        [0, 1, 0],
      ],
    ],
    TetrominoType.t: [
      [
        [0, 1, 0],
        [1, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 1, 0],
        [0, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 0, 0],
        [1, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 1, 0],
        [1, 1, 0],
        [0, 1, 0],
      ],
    ],
    TetrominoType.z: [
      [
        [1, 1, 0],
        [0, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 0, 1],
        [0, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 0, 0],
        [1, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 1, 0],
        [1, 1, 0],
        [1, 0, 0],
      ],
    ],
  };

  /// Возвращает матрицу текущей ротации.
  List<List<int>> get shape => _shapes[type]![rotationIndex];

  /// Размер матрицы (количество строк = количество столбцов).
  int get size => shape.length;

  /// Значение для вставки в поле (1-7).
  int get value => type.value;

  /// Получить цвет фигуры.
  int get color => type.color;

  /// Вращение по часовой стрелке.
  Tetromino rotateCW() {
    return copyWith(rotationIndex: (rotationIndex + 1) % 4);
  }

  /// Вращение против часовой стрелки.
  Tetromino rotateCCW() {
    return copyWith(rotationIndex: (rotationIndex + 3) % 4);
  }

  /// Сдвиг влево.
  Tetromino moveLeft() => copyWith(x: x - 1);

  /// Сдвиг вправо.
  Tetromino moveRight() => copyWith(x: x + 1);

  /// Сдвиг вниз.
  Tetromino moveDown() => copyWith(y: y + 1);
}