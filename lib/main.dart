import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_service.dart';
import 'screens/start_screen.dart';

void main() { 
  runApp(const MyApp()); // Uygulamanın başlangıç noktası, MyApp widget'ını çalıştırır.
}

class MyApp extends StatelessWidget { //değişmeyen yapı
  const MyApp({Key? key}) : super(key: key); 

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider( // Provider paketi kullanarak GameService'i uygulama genelinde erişilebilir hale getirir.
      create: (_) => GameService(),
      child: MaterialApp(
        title: 'Stratejik Sayı Oyunu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A15),
        ),
        home: const StartScreen(), //ilk açılan ekran
      ),
    );
  }
}