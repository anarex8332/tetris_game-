/// Перечисление всех 7 типов фигур Тетриса с каноническими цветами.
enum TetrominoType {
  i(1, 'I', 0xFF00F0F0), // Голубой (Cyan)
  j(2, 'J', 0xFF0000F0), // Синий (Blue)
  l(3, 'L', 0xFFF0A000), // Оранжевый (Orange)
  o(4, 'O', 0xFFF0F000), // Жёлтый (Yellow)
  s(5, 'S', 0xFF00F000), // Зелёный (Green)
  t(6, 'T', 0xFFA000F0), // Фиолетовый (Purple)
  z(7, 'Z', 0xFFF00000); // Красный (Red)

  final int value;   // Числовое представление (1-7) для поля
  final String label;
  final int color;   // HEX-цвет

  const TetrominoType(this.value, this.label, this.color);

  /// Получить [TetrominoType] по числовому значению (1-7).
  static TetrominoType? fromValue(int value) {
    return TetrominoType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => throw ArgumentError('Invalid tetromino value: $value'),
    );
  }
}