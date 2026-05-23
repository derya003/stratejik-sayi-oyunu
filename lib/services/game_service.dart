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

// Her sayı için puan değerleri (ödev tablosuna göre)
const Map<int, int> blockPoints = {
  1: 1,
  2: 2,
  3: 3,
  4: 5,
  5: 7,
  6: 9,
  7: 12,
  8: 15,
  9: 20,
};

class FallingBlock {
  Block block;
  int col;
  double row;

  FallingBlock({required this.block, required this.col, required this.row});
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

  // --- YENİ: Puan alanları ---
  int score = 0;
  int _spawnIntervalSeconds = 5; // mevcut spawn süresi

  final Random _random = Random();
  Timer? _fallTimer;

  // GameScreen'deki spawn timer'ı güncellemek için callback
  // (GameScreen bu callback'i set eder)
  VoidCallback? onSpawnIntervalChanged;

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
    score = 0;
    _spawnIntervalSeconds = 5;

    for (int r = ROWS - 3; r < ROWS; r++) {
      for (int c = 0; c < COLS; c++) {
        board[r][c] = _randomBlock();
      }
    }

    _generateTarget();
    _startFallLoop();
    notifyListeners();
  }

  // Puana göre spawn süresini hesapla
  int _calcSpawnInterval() {
    if (score >= 400) return 1;
    if (score >= 300) return 2;
    if (score >= 200) return 3;
    if (score >= 100) return 4;
    return 5;
  }

  void _startFallLoop() {
    _fallTimer?.cancel();
    _fallTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _tickFalling();
    });
  }

  void _tickFalling() {
    if (isGameOver || fallingBlocks.isEmpty) return;

    List<FallingBlock> toRemove = [];

    for (final fb in fallingBlocks) {
      fb.row += 0.25;
      int currentRowInt = fb.row.floor();
      int landingRow = _findLandingRow(fb.col);

      if (currentRowInt >= landingRow) {
        if (landingRow >= 0 && landingRow < ROWS) {
          board[landingRow][fb.col] = fb.block;
        }
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
      if (board[r][col] == null) return r;
    }
    return -1;
  }

  void spawnNewBlock() {
    if (isGameOver) return;

    List<int> availableCols = [];
    for (int c = 0; c < COLS; c++) {
      if (board[0][c] == null) availableCols.add(c);
    }

    if (availableCols.isEmpty) {
      isGameOver = true;
      message = 'Oyun Bitti! Tahta doldu.';
      notifyListeners();
      return;
    }

    int col = availableCols[_random.nextInt(availableCols.length)];
    fallingBlocks.add(FallingBlock(
      block: _randomBlock(),
      col: col,
      row: -1.0,
    ));
    notifyListeners();
  }

  Block _randomBlock() {
    int value = _random.nextInt(9) + 1;
    return Block(value: value, color: blockColors[value]!);
  }

  void _generateTarget() {
    List<Block> allBlocks = [];
    for (var row in board) {
      for (var b in row) {
        if (b != null) allBlocks.add(b);
      }
    }
    if (allBlocks.length < 2) return;

    allBlocks.shuffle();
    int count = _random.nextInt(3) + 2;
    int sum = 0;
    for (int i = 0; i < count; i++) {
      sum += allBlocks[i].value;
    }
    targetNumber = sum;
    notifyListeners();
  }

  void toggleBlock(int row, int col) {
    if (isGameOver) return;
    final pos = Position(row, col);
    if (board[row][col] == null) return;

    if (selectedPositions.contains(pos)) {
      selectedPositions.remove(pos);
      board[row][col]!.isSelected = false;
      message = null;
      notifyListeners();
      return;
    }

    if (selectedPositions.length >= MAX_SELECTED) {
      message = 'En fazla 4 blok seçebilirsin!';
      notifyListeners();
      return;
    }

    if (selectedPositions.isEmpty) {
      selectedPositions.add(pos);
      board[row][col]!.isSelected = true;
      message = null;
      notifyListeners();
      return;
    }

    bool isNeighbor = selectedPositions.any((s) => s.neighbors.contains(pos));
    if (!isNeighbor) {
      message = 'Sadece komşu blokları seçebilirsin!';
      notifyListeners();
      return;
    }

    selectedPositions.add(pos);
    board[row][col]!.isSelected = true;
    message = null;
    notifyListeners();
  }

  void confirmSelection() {
    if (selectedPositions.length < MIN_SELECTED) {
      message = 'En az 2 blok seçmelisin!';
      notifyListeners();
      return;
    }

    int total = selectedPositions.fold(
        0, (sum, pos) => sum + (board[pos.row][pos.col]?.value ?? 0));

    if (total == targetNumber) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  void _handleCorrect() {
    // Puan hesapla
    int gained = selectedPositions.fold(
        0,
        (sum, pos) =>
            sum + (blockPoints[board[pos.row][pos.col]?.value ?? 0] ?? 0));
    score += gained;

    message = '🎉 Doğru! +$gained puan kazandın!';

    for (final pos in selectedPositions) {
      board[pos.row][pos.col] = null;
    }
    selectedPositions = [];

    // BUG FIX: wrongCount sıfırlanmıyor artık

    _applyGravity();
    _generateTarget();

    // Süre azalma: puan değişince spawn interval güncelle
    final newInterval = _calcSpawnInterval();
    if (newInterval != _spawnIntervalSeconds) {
      _spawnIntervalSeconds = newInterval;
      onSpawnIntervalChanged?.call(); // GameScreen'e haber ver
    }

    notifyListeners();
  }

  void _handleWrong() {
    wrongCount++;
    for (final pos in selectedPositions) {
      board[pos.row][pos.col]?.isSelected = false;
    }
    selectedPositions = [];

    if (wrongCount >= MAX_WRONG) {
      message = '❌ 3 yanlış! Tüm sütunlara yeni blok iniyor!';
      wrongCount = 0;
      _addRowToTop();
    } else {
      message = '❌ Yanlış! ($wrongCount/$MAX_WRONG hata)';
    }
    notifyListeners();
  }

  void cancelSelection() {
    for (final pos in selectedPositions) {
      board[pos.row][pos.col]?.isSelected = false;
    }
    selectedPositions = [];
    message = null;
    notifyListeners();
  }

  void _applyGravity() {
    for (int c = 0; c < COLS; c++) {
      List<Block> colBlocks = [];
      for (int r = 0; r < ROWS; r++) {
        if (board[r][c] != null) colBlocks.add(board[r][c]!);
      }
      for (int r = 0; r < ROWS; r++) {
        int offset = ROWS - colBlocks.length;
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

  int get spawnIntervalSeconds => _spawnIntervalSeconds;

  @override
  void dispose() {
    _fallTimer?.cancel();
    super.dispose();
  }

  int get selectedSum => selectedPositions.fold(
      0, (sum, pos) => sum + (board[pos.row][pos.col]?.value ?? 0));
}