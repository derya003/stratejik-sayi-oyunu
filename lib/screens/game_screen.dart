import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../widgets/game_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    _startSpawnTimer();
  }

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final game = context.read<GameService>();
      if (!game.isGameOver) {
        game.spawnNewBlock();
      }
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1D1F35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text(
          'Oyun Bitti',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Tahta doldu. Yeniden başlamak ister misin?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  context.read<GameService>().restartGame();
                  _startSpawnTimer();
                },
                child: const Text(
                  'Tekrar Oyna',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.isGameOver) {
        _spawnTimer?.cancel();
        _showGameOverDialog();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF17182B),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildTopBar(game),
            const SizedBox(height: 10),
            if (game.message != null) _buildMessageBox(game),
            const SizedBox(height: 8),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: GameBoard(),
              ),
            ),
            const SizedBox(height: 10),
            _buildBottomInfo(game),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(GameService game) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoItem(
            title: 'HEDEF',
            value: '${game.targetNumber}',
            valueColor: const Color(0xFFFBC02D),
            align: CrossAxisAlignment.start,
          ),
          _buildInfoItem(
            title: 'SEÇİLİ TOPLAM',
            value: '${game.selectedSum}',
            valueColor: game.selectedSum == game.targetNumber
                ? const Color(0xFF66BB6A)
                : game.selectedSum > game.targetNumber
                    ? const Color(0xFFEF5350)
                    : Colors.white,
            align: CrossAxisAlignment.center,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'HATA',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.only(left: 5),
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < game.wrongCount
                          ? const Color(0xFFE57373)
                          : Colors.white12,
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    required Color valueColor,
    required CrossAxisAlignment align,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBox(GameService game) {
    final isSuccess = game.message!.contains('Doğru');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF66BB6A).withOpacity(0.10)
            : const Color(0xFFEF5350).withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF66BB6A).withOpacity(0.25)
              : const Color(0xFFEF5350).withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color:
                isSuccess ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              game.message!,
              style: TextStyle(
                color: isSuccess
                    ? const Color(0xFF81C784)
                    : const Color(0xFFE57373),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(GameService game) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.pan_tool_alt_rounded,
                color: Colors.white54,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Sürükleyerek seç',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              '${game.selectedPositions.length}/4 blok',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}