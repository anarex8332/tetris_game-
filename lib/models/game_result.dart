/// Модель результата игры для сохранения в топ-5.
class GameResult {
  final int score;
  final int level;
  final int lines;
  final DateTime date;
  final String? playerName;

  GameResult({
    required this.score,
    required this.level,
    required this.lines,
    required this.date,
    this.playerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'level': level,
      'lines': lines,
      'date': date.toIso8601String(),
      'playerName': playerName,
    };
  }

  factory GameResult.fromJson(Map<String, dynamic> json) {
    return GameResult(
      score: json['score'] as int,
      level: json['level'] as int,
      lines: json['lines'] as int,
      date: DateTime.parse(json['date'] as String),
      playerName: json['playerName'] as String?,
    );
  }
}