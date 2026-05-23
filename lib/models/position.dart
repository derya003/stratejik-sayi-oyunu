class Position {
  final int row;
  final int col;

  const Position(this.row, this.col); // yeni oluşrtur

  @override
  bool operator ==(Object other) => // iki position aynı mı kontrol ediyor
      other is Position && other.row == row && other.col == col; 

  @override
  int get hashCode => row.hashCode ^ col.hashCode; // position'ların hash kodunu oluşturur, böylece aynı pozisyonlar aynı hash koduna sahip olur

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