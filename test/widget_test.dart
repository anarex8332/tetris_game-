import 'package:flutter_test/flutter_test.dart';
import 'package:tetris_game/models/board.dart';
import 'package:tetris_game/models/tetromino.dart';
import 'package:tetris_game/models/tetromino_type.dart';
import 'package:tetris_game/models/seven_bag.dart';
import 'package:tetris_game/models/game_controller.dart';
import 'package:tetris_game/painters/board_painter.dart';

void main() {
  test('GameBoard initializes correctly', () {
    final board = GameBoard();
    expect(GameBoard.width, 10);
    expect(GameBoard.height, 20);
    for (int row = 0; row < GameBoard.height; row++) {
      for (int col = 0; col < GameBoard.width; col++) {
        expect(board.board[row][col], 0);
      }
    }
  });

  test('SevenBagGenerator produces all 7 types in first bag', () {
    final bag = SevenBagGenerator();
    final types = <int>{};
    for (int i = 0; i < 7; i++) {
      final piece = bag.next();
      types.add(piece.type.value);
    }
    expect(types.length, 7);
    for (int v = 1; v <= 7; v++) {
      expect(types.contains(v), true);
    }
  });

  test('Tetromino rotates correctly', () {
    final piece = Tetromino(type: TetrominoType.t);
    expect(piece.rotationIndex, 0);

    final rotated = piece.rotateCW();
    expect(rotated.rotationIndex, 1);

    final rotatedBack = rotated.rotateCCW();
    expect(rotatedBack.rotationIndex, 0);
  });

  test('WallKicks handles O-piece (no kicks needed)', () {
    final piece = Tetromino(type: TetrominoType.o, x: 4, y: 10);
    final board = GameBoard();
    final rotated = piece.rotateCW();
    expect(board.canPlace(rotated), true);
  });

  test('Board painter creates without error', () {
    final board = GameBoard();
    final painter = BoardPainter(
      gameBoard: board,
      cellSize: 30.0,
    );
    expect(painter, isNotNull);
  });

  test('GameController starts in playing state', () {
    final ctrl = GameController();
    expect(ctrl.state, GameState.playing);
    expect(ctrl.score, 0);
    expect(ctrl.level, 1);
    expect(ctrl.linesCleared, 0);
  });

  test('GameController can move piece left and right', () {
    final ctrl = GameController();
    final initialX = ctrl.currentPiece!.x;

    ctrl.moveLeft();
    expect(ctrl.currentPiece!.x, initialX - 1);

    ctrl.moveRight();
    expect(ctrl.currentPiece!.x, initialX);
  });

  test('GameController hold works', () {
    final ctrl = GameController();
    final firstType = ctrl.currentPiece!.type;

    ctrl.hold();
    expect(ctrl.holdPiece, firstType);
    expect(ctrl.currentPiece!.type, isNot(firstType));
  });

  test('GameController rotateCCW works', () {
    final ctrl = GameController();
    final initialRotation = ctrl.currentPiece!.rotationIndex;

    ctrl.rotate();
    expect(ctrl.currentPiece!.rotationIndex, (initialRotation + 1) % 4);

    ctrl.rotateCCW();
    expect(ctrl.currentPiece!.rotationIndex, initialRotation);
  });

  test('NES scoring - single line clears correctly', () {
    final ctrl = GameController();
    for (int col = 0; col < GameBoard.width; col++) {
      ctrl.board.board[GameBoard.height - 1][col] = 1;
    }
    final cleared = ctrl.board.clearFullLines();
    expect(cleared, 1);
  });
}