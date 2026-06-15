import 'package:flutter/material.dart';
import '../models/tetromino_type.dart';

/// Цветовая палитра "Советский Союз" для оформления игры.
class USSRColors {
  // Основные
  static const Color red = Color(0xFFD32F2F);
  static const Color darkRed = Color(0xFF8B0000);
  static const Color orange = Color(0xFFD84315);
  static const Color yellow = Color(0xFFFFD54F);
  static const Color gold = Color(0xFFFFB300);
  static const Color olive = Color(0xFF556B2F);
  static const Color green = Color(0xFF388E3C);
  static const Color teal = Color(0xFF00796B);
  static const Color blue = Color(0xFF1976D2);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color purple = Color(0xFF5E35B1);

  // Нейтральные
  static const Color black = Color(0xFF212121);
  static const Color darkGray = Color(0xFF424242);
  static const Color gray = Color(0xFF757575);
  static const Color beige = Color(0xFFEFEBE9);
  static const Color cream = Color(0xFFFFF8E1);
  static const Color white = Color(0xFFFFFFFF);

  // Фоны
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color backgroundBeige = Color(0xFFD4C4A8);
  static const Color panelRed = Color(0xFFC41E3A);
}

/// Советские цвета фигур.
const Map<TetrominoType, Color> ussrTetrominoColors = {
  TetrominoType.i: USSRColors.teal,
  TetrominoType.o: USSRColors.gold,
  TetrominoType.t: USSRColors.purple,
  TetrominoType.s: USSRColors.olive,
  TetrominoType.z: USSRColors.red,
  TetrominoType.j: USSRColors.blue,
  TetrominoType.l: USSRColors.orange,
};

/// Вспомогательный класс для получения советского цвета фигуры.
Color getUssrColor(TetrominoType type) => ussrTetrominoColors[type] ?? Colors.grey;