import 'dart:math';
import 'tetromino_type.dart';
import 'tetromino.dart';

/// Реализация "7-Bag Randomizer" — стандартный генератор фигур в Тетрисе.
///
/// Принцип работы:
/// - В "мешок" кладутся все 7 уникальных фигур (I, J, L, O, S, T, Z).
/// - Мешок перемешивается (Fisher-Yates shuffle).
/// - Фигуры выдаются по одной из мешка.
/// - Когда мешок пуст — создаётся новый перемешанный мешок.
/// - Это гарантирует, что каждая фигура выпадет ровно 1 раз за 7 ходов,
///   но порядок внутри каждой "семёрки" случайный.
class SevenBagGenerator {
  final Random _random;
  final List<TetrominoType> _bag = [];
  int _index = 0;

  SevenBagGenerator({Random? random})
      : _random = random ?? Random();

  /// Возвращает следующую фигуру из мешка.
  Tetromino next() {
    if (_index >= _bag.length) {
      _refillBag();
    }
    final type = _bag[_index];
    _index++;
    return Tetromino(type: type);
  }

  /// Позволяет заглянуть на [count] следующих фигур без их извлечения.
  /// Используется для отображения "Next Queue" (следующие фигуры).
  List<TetrominoType> peek(int count) {
    while (_bag.length - _index < count) {
      _refillBag();
    }
    return _bag.sublist(_index, _index + count);
  }

  /// Сброс генератора — очищает мешок и начинает заново.
  void reset() {
    _bag.clear();
    _index = 0;
  }

  /// Наполняет мешок новыми 7 фигурами и перемешивает.
  void _refillBag() {
    final newBag = List<TetrominoType>.of(TetrominoType.values);
    _shuffle(newBag);
    _bag.addAll(newBag);
  }

  /// Fisher-Yates shuffle для списка.
  void _shuffle(List<TetrominoType> list) {
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }
}