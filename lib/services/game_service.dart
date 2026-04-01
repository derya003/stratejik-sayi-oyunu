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
  double row; // ekranın üstünden başlar (-1.0), aşağı iner

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

  final Random _random = Random();
  Timer? _fallTimer;

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

    // İlk 3 satırı doldur (en alt 3 satır: 7, 8, 9)
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
    // Her 80ms'de blokları aşağı indir
    _fallTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _tickFalling();
    });
  }

  void _tickFalling() {
    if (isGameOver || fallingBlocks.isEmpty) return;

    List<FallingBlock> toRemove = [];

    for (final fb in fallingBlocks) {
      fb.row += 0.25; // her 80ms'de 0.25 satır iner → yaklaşık 3.2sn'de 10 satır

      int currentRowInt = fb.row.floor();

      // Duracağı yeri hesapla: bu sütunda en üstteki dolu hücre
      int landingRow = _findLandingRow(fb.col);

      // Blok yerleşme noktasına geldi mi?
      if (currentRowInt >= landingRow) {
        // Tam landingRow'a oturt
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

  // Bu sütunda bloğun oturacağı satırı bul
  // (en alttaki boş satır = tabanın üstü ya da başka bloğun üstü)
  int _findLandingRow(int col) {
    // En alttan yukarı tara, ilk boş satırı bul
    for (int r = ROWS - 1; r >= 0; r--) {
      if (board[r][col] == null) {
        return r; // bu satır boş, buraya oturur
      }
    }
    return -1; // sütun tamamen dolu
  }

  // Her 5 saniyede bir GameScreen bu fonksiyonu çağırır
  void spawnNewBlock() {
    if (isGameOver) return;

    // Tamamen dolu olmayan sütunlardan rastgele seç
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
      row: -1.0, // ekranın üstünden başla
    ));
    notifyListeners();
  }

  Block _randomBlock() {
    int value = _random.nextInt(9) + 1;
    return Block(value: value, color: blockColors[value]!);
  }

  void _generateTarget() {
    targetNumber = _random.nextInt(30) + 3;
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
    message = '🎉 Doğru! Bloklar patladı!';
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

  @override
  void dispose() {
    _fallTimer?.cancel();
    super.dispose();
  }

  int get selectedSum => selectedPositions.fold(
      0, (sum, pos) => sum + (board[pos.row][pos.col]?.value ?? 0));
}