import 'package:flutter/material.dart';
import 'audio_manager.dart';
import 'board.dart';
import 'tetromino.dart';
import 'tetromino_type.dart';
import 'seven_bag.dart';
import 'wall_kicks.dart';

/// Состояние игры.
enum GameState { menu, playing, paused, gameOver }

/// Контроллер игры с ValueNotifier-подходом для минимальных перерисовок.
class GameController extends ChangeNotifier {
  final GameBoard board = GameBoard();
  final SevenBagGenerator bag = SevenBagGenerator();

  // Текущее состояние
  GameState _state = GameState.playing;
  GameState get state => _state;

  // Активная фигура
  Tetromino? _currentPiece;
  Tetromino? get currentPiece => _currentPiece;

  // Hold
  TetrominoType? _holdPiece;
  TetrominoType? get holdPiece => _holdPiece;
  bool _holdUsed = false;

  // Счёт (NES Tetris)
  int _score = 0;
  int get score => _score;

  int _level = 1;
  int get level => _level;

  int _linesCleared = 0;
  int get linesCleared => _linesCleared;

  // Для отображения следующих фигур
  int get nextCount => 5;

  // TETRIS! анимация
  bool _tetrisTriggered = false;
  bool get tetrisTriggered => _tetrisTriggered;

  // Line clear анимация (1-3 линии)
  int _lastClearedCount = 0;
  int get lastClearedCount => _lastClearedCount;

  // Гравитация (тики Ticker)
  int _gravityTicks = 0;

  // Lock delay
  int _lockDelayTicks = 0;
  static const int maxLockDelayTicks = 30; // ~0.5 сек при 60fps

  bool _lockDelayActive = false;

  GameController() {
    _spawnNewPiece();
  }

  /// Скорость гравитации в тиках (чем меньше, тем быстрее).
  int get gravityInterval {
    // NES-style: 48, 43, 38, 33, 28, 23, 18, 13, 8, 6, 5, 5, 5, 4, 4, 4, 3, 3, 3
    // Упрощённая версия: level 1-9: decrease, 10+: fast
    if (_level <= 9) return 48 - (_level - 1) * 5;
    if (_level <= 12) return 6;
    if (_level <= 15) return 5;
    if (_level <= 18) return 4;
    return 3;
  }

  // ========== ИГРОВОЙ ЦИКЛ ==========

  /// Вызывается каждый кадр (через Ticker).
  void tick() {
    if (_state != GameState.playing || _currentPiece == null) return;

    _gravityTicks++;
    if (_gravityTicks >= gravityInterval) {
      _gravityTicks = 0;
      _applyGravity();
    }

    // Lock delay отсчёт
    if (_lockDelayActive) {
      _lockDelayTicks++;
      if (_lockDelayTicks >= maxLockDelayTicks) {
        _lockAndSpawn();
      }
    }
  }

  void _applyGravity() {
    if (_currentPiece == null) return;

    final moved = _currentPiece!.moveDown();
    if (board.canPlace(moved)) {
      _currentPiece = moved;
      _lockDelayActive = false;
      _lockDelayTicks = 0;
      notifyListeners();
    } else {
      // Фигура не может двигаться вниз — начинаем lock delay
      if (!_lockDelayActive) {
        _lockDelayActive = true;
        _lockDelayTicks = 0;
      }
    }
  }

  void _lockAndSpawn() {
    if (_currentPiece == null) return;

    final locked = board.lockPiece(_currentPiece!);
    if (!locked) {
      // Game Over
      _state = GameState.gameOver;
      _currentPiece = null;
      AudioManager().playGameOver();
      notifyListeners();
      return;
    }

    // Очистка линий и подсчёт очков
    final cleared = board.clearFullLines();
    if (cleared > 0) {
      _addScore(cleared);
      _linesCleared += cleared;

      // Повышение уровня каждые 10 линий
      final newLevel = (_linesCleared ~/ 10) + 1;
      if (newLevel > _level) {
        _level = newLevel;
      }
    }

    // Звук + анимация очистки
    _lastClearedCount = cleared;
    if (cleared > 0 && cleared < 4) {
      AudioManager().playClear(cleared);
    }

    // TETRIS! анимация при 4 линиях
    if (cleared == 4) {
      AudioManager().playTetris();
      _tetrisTriggered = true;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 900), () {
        _tetrisTriggered = false;
        notifyListeners();
      });
    }

    _holdUsed = false;
    _lockDelayActive = false;
    _lockDelayTicks = 0;
    _spawnNewPiece();
    notifyListeners();
  }

  void _spawnNewPiece() {
    _currentPiece = bag.next();

    // Проверка Game Over: если новая фигура не помещается
    if (!board.canPlace(_currentPiece!)) {
      _state = GameState.gameOver;
      _currentPiece = null;
    }
    _gravityTicks = 0;
    notifyListeners();
  }

  // ========== УПРАВЛЕНИЕ ==========

  /// Перемещение влево.
  void moveLeft() {
    if (_state != GameState.playing || _currentPiece == null) return;
    final moved = _currentPiece!.moveLeft();
    if (board.canPlace(moved)) {
      _currentPiece = moved;
      _lockDelayActive = false;
      _lockDelayTicks = 0;
      AudioManager().playMove();
      notifyListeners();
    }
  }

  /// Перемещение вправо.
  void moveRight() {
    if (_state != GameState.playing || _currentPiece == null) return;
    final moved = _currentPiece!.moveRight();
    if (board.canPlace(moved)) {
      _currentPiece = moved;
      _lockDelayActive = false;
      _lockDelayTicks = 0;
      AudioManager().playMove();
      notifyListeners();
    }
  }

  /// Поворот по часовой стрелке (с Wall Kicks).
  void rotate() {
    if (_state != GameState.playing || _currentPiece == null) return;
    final rotated = WallKicks.tryRotateCW(
      _currentPiece!,
      (p) => board.canPlace(p),
    );
    if (rotated != null) {
      _currentPiece = rotated;
      _lockDelayActive = false;
      _lockDelayTicks = 0;
      AudioManager().playRotate();
      notifyListeners();
    }
  }

  /// Поворот против часовой стрелки (с Wall Kicks).
  void rotateCCW() {
    if (_state != GameState.playing || _currentPiece == null) return;
    final rotated = WallKicks.tryRotateCCW(
      _currentPiece!,
      (p) => board.canPlace(p),
    );
    if (rotated != null) {
      _currentPiece = rotated;
      _lockDelayActive = false;
      _lockDelayTicks = 0;
      AudioManager().playRotate();
      notifyListeners();
    }
  }

  /// Soft Drop: смещение вниз на 1 с +1 очком.
  void softDrop() {
    if (_state != GameState.playing || _currentPiece == null) return;
    final moved = _currentPiece!.moveDown();
    if (board.canPlace(moved)) {
      _currentPiece = moved;
      _score += 1;
      _lockDelayActive = false;
      _lockDelayTicks = 0;
      notifyListeners();
    }
  }

  /// Hard Drop: мгновенный сброс до дна.
  void hardDrop() {
    if (_state != GameState.playing || _currentPiece == null) return;

    int dropDistance = 0;
    while (board.canPlace(_currentPiece!.moveDown())) {
      _currentPiece = _currentPiece!.moveDown();
      dropDistance++;
    }

    _score += dropDistance * 2;
    AudioManager().playDrop();
    _lockAndSpawn();
  }

  /// Hold: отложить фигуру.
  void hold() {
    if (_state != GameState.playing || _currentPiece == null || _holdUsed) return;

    final currentType = _currentPiece!.type;

    if (_holdPiece == null) {
      // Первый hold — просто сохраняем и спавним новую
      _holdPiece = currentType;
      _holdUsed = true;
      _spawnNewPiece();
    } else {
      // Меняем местами
      final swapType = _holdPiece;
      _holdPiece = currentType;
      _holdUsed = true;
      _currentPiece = Tetromino(type: swapType!);

      if (!board.canPlace(_currentPiece!)) {
        _state = GameState.gameOver;
        _currentPiece = null;
      }
      notifyListeners();
    }
  }

  /// Пауза.
  void togglePause() {
    if (_state == GameState.playing) {
      _state = GameState.paused;
    } else if (_state == GameState.paused) {
      _state = GameState.playing;
    }
    notifyListeners();
  }

  /// Рестарт.
  void restart() {
    board.reset();
    bag.reset();
    _score = 0;
    _level = 1;
    _linesCleared = 0;
    _holdPiece = null;
    _holdUsed = false;
    _lockDelayActive = false;
    _lockDelayTicks = 0;
    _gravityTicks = 0;
    _state = GameState.playing;
    _spawnNewPiece();
  }

  /// Сбросить lastClearedCount после анимации.
  void resetLastClearedCount() {
    _lastClearedCount = 0;
  }

  /// Получить следующие [count] фигур для отображения.
  List<TetrominoType> getNextPieces() => bag.peek(nextCount);

  // ========== NES СЧЁТ ==========

  void _addScore(int lines) {
    switch (lines) {
      case 1:
        _score += 40 * _level;
      case 2:
        _score += 100 * _level;
      case 3:
        _score += 300 * _level;
      case 4:
        _score += 1200 * _level;
    }
  }
}