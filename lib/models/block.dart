import 'package:flutter/material.dart';

class Block {
  final int value;
  final Color color;
  bool isSelected;

  Block({
    required this.value,
    required this.color,
    this.isSelected = false,
  });

  Block copyWith({int? value, Color? color, bool? isSelected}) {
    return Block(
      value: value ?? this.value,
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// Her sayı için sabit renk tanımları
const Map<int, Color> blockColors = {
  1: Color(0xFFFF6B6B), // canlı mercan kırmızı
  2: Color(0xFFFFA94D), // sıcak turuncu
  3: Color(0xFFFFD43B), // canlı sarı
  4: Color(0xFF69DB7C), // taze yeşil
  5: Color(0xFF4D96FF), // temiz mavi
  6: Color(0xFF9775FA), // mor-lila
  7: Color(0xFFF06595), // canlı pembe
  8: Color(0xFF22D3EE), // açık turkuaz
  9: Color(0xFFFF922B), // koyu altın-turuncu

};