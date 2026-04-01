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
  1: Color(0xFFFF6B6B), // kırmızı
  2: Color(0xFFFF9F43), // turuncu
  3: Color(0xFFFFD93D), // sarı
  4: Color(0xFF6BCB77), // yeşil
  5: Color(0xFF4D96FF), // mavi
  6: Color(0xFF845EC2), // mor
  7: Color.fromARGB(255, 253, 84, 141), // pembe
  8: Color(0xFF00C9A7), // turkuaz
  9: Color(0xFFFF5252), // koyu kırmızı
};