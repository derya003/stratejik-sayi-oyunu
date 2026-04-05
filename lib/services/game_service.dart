import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/block.dart';
import '../models/position.dart';

const int ROWS = 10;
const int COLS = 8;
const int MAX_SELECTED = 4;
const int MIN_SELECTED = 2;
const int MAX_WRONG = 3;

class FallingBlock {
  Block block;
  int col;
  double row;

  FallingBlock({
    required this.block,
    required this.col,
    required this.row,
  });
}

class GameService extends ChangeNotifier {
  List<List<Block?>> board =
      List.generate(ROWS, (_) => List.filled(COLS, null));

  List<FallingBlock> fallingBlocks = [];
  List<Position> selectedPositions = [];

  int targetNumber = 0;
  int wrongCount = 0;
  bool isGameOver = false;
  String? message;

  final Random _random = Random();
  Timer? _fallTimer;

  bool _isDragging = false;

  GameService() {
    _initGame();
  }

  void _initGame() {
    board = List.generate(ROWS, (_) => List.filled(COLS, null));
    fallingBlocks = [];
    selectedPositions = [];
    wrongCount = 0;
    isGameOver = false;
    message = null;
    _isDragging = false;

    // İlk 3 satırı alttan doldur
    for (int r = ROWS - 3; r < ROWS; r++) {
      for (int c = 0; c < COLS; c++) {
        board[r][c] = _randomBlock();
      }
    }

    _generateTarget();
    _startFallLoop();
    notifyListeners();
  }

  void _startFallLoop() {
    _fallTimer?.cancel();
    _fallTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _tickFalling();
    });
  }

  void _tickFalling() {
    if (isGameOver || fallingBlocks.isEmpty) return;

    final List<FallingBlock> toRemove = [];

    for (final fb in fallingBlocks) {
      fb.row += 0.25;

      final int currentRowInt = fb.row.floor();
      final int landingRow = _findLandingRow(fb.col);

      if (landingRow == -1) {
        isGameOver = true;
        message = 'Oyun Bitti! Tahta doldu.';
        notifyListeners();
        return;
      }

      if (currentRowInt >= landingRow) {
        board[landingRow][fb.col] = fb.block;
        toRemove.add(fb);
        _checkGameOver();
      }
    }

    for (final fb in toRemove) {
      fallingBlocks.remove(fb);
    }

    notifyListeners();
  }

  int _findLandingRow(int col) {
    for (int r = ROWS - 1; r >= 0; r--) {
      if (board[r][col] == null) {
        return r;
      }
    }
    return -1;
  }

  void spawnNewBlock() {
    if (isGameOver) return;

    final List<int> availableCols = [];
    for (int c = 0; c < COLS; c++) {
      if (board[0][c] == null) {
        availableCols.add(c);
      }
    }

    if (availableCols.isEmpty) {
      isGameOver = true;
      message = 'Oyun Bitti! Tahta doldu.';
      notifyListeners();
      return;
    }

    final int col = availableCols[_random.nextInt(availableCols.length)];

    fallingBlocks.add(
      FallingBlock(
        block: _randomBlock(),
        col: col,
        row: -1.0,
      ),
    );

    notifyListeners();
  }

  Block _randomBlock() {
    final int value = _random.nextInt(9) + 1;
    return Block(value: value, color: blockColors[value]!);
  }

  void _generateTarget() {
    targetNumber = _random.nextInt(30) + 3;
  }

  bool _isNeighbor(Position a, Position b) {
    final rowDiff = (a.row - b.row).abs();
    final colDiff = (a.col - b.col).abs();

    // yatay, dikey, çapraz komşuluk
    return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0);
  }

  void _clearSelectionFlags() {
    for (final pos in selectedPositions) {
      board[pos.row][pos.col]?.isSelected = false;
    }
  }

  void beginSelection(int row, int col) {
    if (isGameOver) return;
    if (row < 0 || row >= ROWS || col < 0 || col >= COLS) return;
    if (board[row][col] == null) return;

    cancelSelection(clearMessage: false);

    _isDragging = true;
    final pos = Position(row, col);
    selectedPositions.add(pos);
    board[row][col]!.isSelected = true;
    message = null;
    notifyListeners();
  }

  void extendSelection(int row, int col) {
    if (!_isDragging || isGameOver) return;
    if (row < 0 || row >= ROWS || col < 0 || col >= COLS) return;
    if (board[row][col] == null) return;

    final pos = Position(row, col);

    if (selectedPositions.isEmpty) return;

    // Aynı hücreye tekrar gelindiyse bir şey yapma
    if (selectedPositions.last == pos) return;

    // Geriye doğru gidildiyse son seçimi kaldır
    if (selectedPositions.length >= 2 &&
        selectedPositions[selectedPositions.length - 2] == pos) {
      final last = selectedPositions.removeLast();
      board[last.row][last.col]?.isSelected = false;
      message = null;
      notifyListeners();
      return;
    }

    // Daha önce seçilmişse alma
    if (selectedPositions.contains(pos)) return;

    // En fazla 4 blok
    if (selectedPositions.length >= MAX_SELECTED) return;

    // Sadece son seçilen bloğa komşu olmalı
    final last = selectedPositions.last;
    if (!_isNeighbor(last, pos)) return;

    selectedPositions.add(pos);
    board[row][col]!.isSelected = true;
    message = null;
    notifyListeners();
  }

  void endSelection() {
    if (!_isDragging) return;
    _isDragging = false;

    if (selectedPositions.length < MIN_SELECTED) {
      cancelSelection(clearMessage: true);
      return;
    }

    final int total = selectedPositions.fold(
      0,
      (sum, pos) => sum + (board[pos.row][pos.col]?.value ?? 0),
    );

    if (total == targetNumber) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  void _handleCorrect() {
    message = 'Doğru seçim!';

    for (final pos in selectedPositions) {
      board[pos.row][pos.col] = null;
    }

    selectedPositions = [];
    wrongCount = 0;

    _applyGravity();
    _generateTarget();
    notifyListeners();
  }

  void _handleWrong() {
    wrongCount++;
    _clearSelectionFlags();
    selectedPositions = [];

    if (wrongCount >= MAX_WRONG) {
      message = '3 yanlış! Yeni bloklar iniyor!';
      wrongCount = 0;
      _addRowToTop();
    } else {
      message = 'Yanlış seçim! ($wrongCount/$MAX_WRONG)';
    }

    notifyListeners();
  }

  void cancelSelection({bool clearMessage = true}) {
    _clearSelectionFlags();
    selectedPositions = [];
    _isDragging = false;

    if (clearMessage) {
      message = null;
    }

    notifyListeners();
  }

  void _applyGravity() {
    for (int c = 0; c < COLS; c++) {
      final List<Block> colBlocks = [];

      for (int r = 0; r < ROWS; r++) {
        if (board[r][c] != null) {
          colBlocks.add(board[r][c]!);
        }
      }

      for (int r = 0; r < ROWS; r++) {
        final offset = ROWS - colBlocks.length;
        board[r][c] = r < offset ? null : colBlocks[r - offset];
      }
    }

    _checkGameOver();
  }

  void _addRowToTop() {
    for (int c = 0; c < COLS; c++) {
      if (board[0][c] != null) {
        isGameOver = true;
        message = 'Oyun Bitti!';
        notifyListeners();
        return;
      }
    }

    for (int c = 0; c < COLS; c++) {
      board[0][c] = _randomBlock();
    }

    _applyGravity();
    _checkGameOver();
  }

  void _checkGameOver() {
    for (int c = 0; c < COLS; c++) {
      if (board[0][c] != null) {
        isGameOver = true;
        message = 'Oyun Bitti! Sütun doldu.';
        notifyListeners();
        return;
      }
    }
  }

  void restartGame() {
    _fallTimer?.cancel();
    _initGame();
  }

  @override
  void dispose() {
    _fallTimer?.cancel();
    super.dispose();
  }

  int get selectedSum => selectedPositions.fold(
        0,
        (sum, pos) => sum + (board[pos.row][pos.col]?.value ?? 0),
      );
}