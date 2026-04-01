class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';

  // Komşu pozisyonları döndür (yatay, dikey, çapraz)
  List<Position> get neighbors => [
        Position(row - 1, col - 1),
        Position(row - 1, col),
        Position(row - 1, col + 1),
        Position(row, col - 1),
        Position(row, col + 1),
        Position(row + 1, col - 1),
        Position(row + 1, col),
        Position(row + 1, col + 1),
      ];
}