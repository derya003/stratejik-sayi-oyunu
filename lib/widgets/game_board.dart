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
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        final cellSize = (maxWidth / COLS < maxHeight / ROWS)
            ? maxWidth / COLS
            : maxHeight / ROWS;

        final boardWidth = cellSize * COLS;
        final boardHeight = cellSize * ROWS;

        Position? lastHandledPosition;

        void handlePoint(Offset localPosition) {
          final rawCol = localPosition.dx / cellSize;
          final rawRow = localPosition.dy / cellSize;

          final col = rawCol.floor();
          final row = rawRow.floor();

          if (row < 0 || row >= ROWS || col < 0 || col >= COLS) return;

          // Hücrenin içinde merkeze yakın geçişleri kabul et
          final localXInCell = rawCol - col;
          final localYInCell = rawRow - row;

          const minThreshold = 0.22;
          const maxThreshold = 0.78;

          final isNearCenter =
              localXInCell >= minThreshold &&
              localXInCell <= maxThreshold &&
              localYInCell >= minThreshold &&
              localYInCell <= maxThreshold;

          if (!isNearCenter) return;

          final currentPos = Position(row, col);

          // Aynı hücreyi tekrar tekrar işleme
          if (lastHandledPosition == currentPos) return;
          lastHandledPosition = currentPos;

          if (game.selectedPositions.isEmpty) {
            game.beginSelection(row, col);
          } else {
            game.extendSelection(row, col);
          }
        }

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => handlePoint(details.localPosition),
            onPanUpdate: (details) => handlePoint(details.localPosition),
            onPanEnd: (_) {
              lastHandledPosition = null;
              game.endSelection();
            },
            onTapDown: (details) => handlePoint(details.localPosition),
            onTapUp: (_) {
              lastHandledPosition = null;
              game.endSelection();
            },
            onTapCancel: () {
              lastHandledPosition = null;
              game.endSelection();
            },
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
                                  onTap: null,
                                ),
                              );
                            }),
                          );
                        }),
                      ),

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
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}