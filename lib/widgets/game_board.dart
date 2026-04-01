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
  Widget build(BuildContext context) {
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
              child: Container(
                color: Colors.black26,
                child: Stack(
                  children: [
                    Column(
                      children: List.generate(ROWS, (row) {
                        return Row(
                          children: List.generate(COLS, (col) {
                            final pos = Position(row, col);
                            final block = game.board[row][col];
                            final isSelected =
                                game.selectedPositions.contains(pos);

                            return SizedBox(
                              width: cellSize,
                              height: cellSize,
                              child: BlockWidget(
                                block: block,
                                isSelected: isSelected,
                                onTap: block != null && !game.isGameOver
                                    ? () => game.toggleBlock(row, col)
                                    : null,
                              ),
                            );
                          }),
                        );
                      }),
                    ),

                    // Düşmekte olan bloklar
                    ...game.fallingBlocks.map((fb) {
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