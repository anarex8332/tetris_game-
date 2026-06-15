import 'tetromino.dart';

/// Игровое поле Тетриса: 10 столбцов × 20 строк.
///
/// Каждая клетка: 0 = пусто, 1–7 = тип фигуры (цвет).
class GameBoard {
  static const int width = 10;
  static const int height = 20;

  final List<List<int>> board;

  GameBoard()
      : board = List.generate(
          height,
          (_) => List.filled(width, 0),
        );

  /// Копирование поля (для отката/превью).
  GameBoard.copy(GameBoard other)
      : board = other.board
            .map((row) => List<int>.of(row))
            .toList();

  /// Проверяет, можно ли разместить фигуру [piece] в текущей позиции.
  bool canPlace(Tetromino piece) {
    final shape = piece.shape;
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) continue;

        final boardX = piece.x + col;
        final boardY = piece.y + row;

        // Выход за левую/правую границу
        if (boardX < 0 || boardX >= width) return false;
        // Выход за нижнюю границу (выше верхней — ок, фигура может появляться сверху)
        if (boardY >= height) return false;
        // Пересечение с застывшими блоками (boardY < 0 — вне поля, игнорируем)
        if (boardY >= 0 && board[boardY][boardX] != 0) return false;
      }
    }
    return true;
  }

  /// Фиксирует фигуру на поле, заполняя клетки значением [piece.value].
  /// Возвращает [true], если фигура успешно зафиксирована.
  /// Возвращает [false], если фигура вышла за верхнюю границу (Game Over).
  bool lockPiece(Tetromino piece) {
    final shape = piece.shape;
    for (int row = 0; row < shape.length; row++) {
      for (int col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) continue;

        final boardX = piece.x + col;
        final boardY = piece.y + row;

        // Если фигура зафиксирована выше поля — Game Over
        if (boardY < 0) return false;

        // Выход за границы не должен происходить при корректной проверке canPlace
        if (boardX < 0 || boardX >= width || boardY >= height) continue;

        board[boardY][boardX] = piece.value;
      }
    }
    return true;
  }

  /// Проверяет, заполнена ли строка [row] полностью.
  bool _isRowFull(int row) {
    return board[row].every((cell) => cell != 0);
  }

  /// Удаляет заполненные строки, сдвигает всё выше вниз.
  /// Возвращает количество очищенных линий.
  int clearFullLines() {
    int cleared = 0;
    for (int row = height - 1; row >= 0; row--) {
      if (_isRowFull(row)) {
        board.removeAt(row);
        board.insert(0, List.filled(width, 0));
        cleared++;
        row++; // Проверяем ту же строку снова (строка сместилась)
      }
    }
    return cleared;
  }

  /// Возвращает Y-позицию "призрака" (ghost piece) — самой нижней
  /// точки, куда можно опустить фигуру без коллизий.
  int getGhostY(Tetromino piece) {
    int ghostY = piece.y;
    while (canPlace(piece.copyWith(y: ghostY + 1))) {
      ghostY++;
    }
    return ghostY;
  }

  /// Сброс поля в начальное состояние.
  void reset() {
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        board[row][col] = 0;
      }
    }
  }

  @override
  String toString() {
    final sb = StringBuffer();
    for (int row = 0; row < height; row++) {
      sb.writeln(board[row].map((c) => c == 0 ? '.' : c.toString()).join(' '));
    }
    return sb.toString();
  }
}