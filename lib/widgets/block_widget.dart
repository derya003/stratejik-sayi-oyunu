import 'package:flutter/material.dart';
import '../models/block.dart';

class BlockWidget extends StatelessWidget {
  final Block? block; 
  final bool isSelected;
  final VoidCallback? onTap; //

  const BlockWidget({ 
    Key? key,
    required this.block,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) { // blok null ise boş bir kutu, değilse değeri gösteren bir kutu oluşturur
    final widgetContent = Padding(
      padding: const EdgeInsets.all(1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: block == null // blok null ise arka plan rengi
              ? Colors.white.withOpacity(0.05)
              : (isSelected ? block!.color : block!.color.withOpacity(0.85)),
          borderRadius: BorderRadius.circular(6),
          border: block == null
              ? null
              : Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 1.5 : 0.8,
                ),
          boxShadow: block == null
              ? null
              : [
                  BoxShadow(
                    color: isSelected
                        ? block!.color.withOpacity(0.25)
                        : Colors.black26,
                    blurRadius: isSelected ? 4 : 2,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: block == null// blok null ise değeri göstermeyen bir widget oluşturur
            ? null
            : Center( 
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${block!.value}',// blok null değilse değeri gösteren bir widget oluşturur
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );

    if (block == null) return widgetContent;// blok null ise tıklanamaz, değilse tıklanabilir bir widget oluşturur

    return GestureDetector(// blok null değilse tıklanabilir bir widget oluşturur
      onTap: onTap,
      child: widgetContent,
    );
  }
}