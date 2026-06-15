import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_result.dart';

/// Хранилище топ-5 лучших результатов.
class ScoreStorage {
  static const String _key = 'tetris_top_scores';

  /// Загрузить топ-5 результатов.
  static Future<List<GameResult>> loadTopScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => GameResult.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
    } catch (e) {
      debugPrint('Error loading scores: $e');
      return [];
    }
  }

  /// Сохранить результат и вернуть обновлённый топ-5.
  static Future<List<GameResult>> saveResult(GameResult result) async {
    try {
      final scores = await loadTopScores();
      scores.add(result);
      scores.sort((a, b) => b.score.compareTo(a.score));
      final top5 = scores.take(5).toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(top5.map((r) => r.toJson()).toList());
      await prefs.setString(_key, jsonString);

      return top5;
    } catch (e) {
      debugPrint('Error saving score: $e');
      return [];
    }
  }

  /// Получить лучший результат (максимальный score).
  static Future<int> loadHighScore() async {
    final top = await loadTopScores();
    return top.isNotEmpty ? top.first.score : 0;
  }
}