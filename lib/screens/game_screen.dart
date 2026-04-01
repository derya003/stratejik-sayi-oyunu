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
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '💀 Oyun Bitti!',
          style: TextStyle(color: Colors.white, fontSize: 24),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4D96FF),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.read<GameService>().restartGame();
                _startSpawnTimer();
              },
              child: const Text('Tekrar Oyna',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
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
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(game),
            const SizedBox(height: 8),
            if (game.message != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: game.message!.contains('Doğru')
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: game.message!.contains('Doğru')
                        ? Colors.green.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  game.message!,
                  style: TextStyle(
                    color: game.message!.contains('Doğru')
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 4),
            Expanded(
              child: const GameBoard(),
            ),
            _buildBottomBar(game),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(GameService game) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('HEDEF',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5)),
              Text(
                '${game.targetNumber}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            children: [
              const Text('SEÇİLİ TOPLAM',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.2)),
              Text(
                '${game.selectedSum}',
                style: TextStyle(
                  color: game.selectedSum == game.targetNumber
                      ? Colors.greenAccent
                      : game.selectedSum > game.targetNumber
                          ? Colors.redAccent
                          : Colors.white70,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('HATA',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Row(
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < game.wrongCount
                          ? Colors.redAccent
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

  Widget _buildBottomBar(GameService game) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: game.selectedPositions.isEmpty
                ? null
                : game.cancelSelection,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('İptal'),
            style:
                TextButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              '${game.selectedPositions.length} / 4 blok',
              style: const TextStyle(
                  color: Colors.white54, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            onPressed: game.selectedPositions.length >= 2
                ? game.confirmSelection
                : null,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Onayla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D96FF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white30,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}