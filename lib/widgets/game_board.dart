import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/position.dart';
import 'block_widget.dart';

const int ROWS = 10;
const int COLS = 8;

class GameBoard extends StatelessWidget {
  const GameBoard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {// GameService'i dinleyerek güncellemeleri alır
    final game = context.watch<GameService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Ekranda gerçekten kullanılabilir alan
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // Hücre boyutunu mevcut alana göre hesapla
        final cellSize = (maxWidth / COLS < maxHeight / ROWS)
            ? maxWidth / COLS
            : maxHeight / ROWS;

        final boardWidth = cellSize * COLS;
        final boardHeight = cellSize * ROWS;

        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(// Oyun tahtasının arka planı
                color: Colors.black26,
                child: Stack( // Oyun tahtası ve düşen blokları üst üste yerleştirmek için Stack kullanıyoruz
                  children: [
                    Column(// Oyun tahtasının hücrelerini oluşturur
                      children: List.generate(ROWS, (row) {
                        return Row(
                          children: List.generate(COLS, (col) {
                            final pos = Position(row, col);
                            final block = game.board[row][col];// Oyun tahtasındaki bloğu alır
                            final isSelected =
                                game.selectedPositions.contains(pos);

                            return SizedBox( // Her hücre için bir BlockWidget oluşturur
                              width: cellSize,
                              height: cellSize,
                              child: BlockWidget(
                                block: block,
                                isSelected: isSelected,
                                onTap: block != null && !game.isGameOver // Eğer hücrede blok varsa ve oyun bitmemişse
                                    ? () => game.toggleBlock(row, col)// Bloğa tıklandığında toggleBlock fonksiyonunu çağırır
                                    : null,
                              ),
                            );
                          }),
                        );
                      }),
                    ),

                    // Düşmekte olan bloklar
                    ...game.fallingBlocks.map((fb) {// Düşmekte olan blokları oyun tahtasının üstünde konumlandırır
                      return Positioned(
                        left: fb.col * cellSize,
                        top: fb.row * cellSize,
                        width: cellSize,
                        height: cellSize,
                        child: BlockWidget(
                          block: fb.block,
                          isSelected: false,
                          onTap: null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}