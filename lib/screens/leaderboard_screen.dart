import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  final int lastScore;

  const LeaderboardScreen({Key? key, required this.lastScore}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<int> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAndSaveScores();
  }

  Future<void> _loadAndSaveScores() async {
    final prefs = await SharedPreferences.getInstance();

    // Mevcut skorları yükle
    final stored = prefs.getStringList('leaderboard') ?? [];
    List<int> scores = stored.map((s) => int.tryParse(s) ?? 0).toList();

    // Yeni skoru ekle
    scores.add(widget.lastScore);

    // Yüksekten düşüğe sırala, en fazla 10 tane tut
    scores.sort((a, b) => b.compareTo(a));
    if (scores.length > 10) scores = scores.sublist(0, 10);

    // Kaydet
    await prefs.setStringList('leaderboard', scores.map((s) => s.toString()).toList());

    setState(() {
      _scores = scores;
      _loading = false;
    });
  }

  Future<void> _clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leaderboard');
    setState(() {
      _scores = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17182B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1F35),
        elevation: 0,
        title: const Text(
          '🏆 Liderlik Tablosu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            tooltip: 'Skorları Temizle',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF1D1F35),
                  title: const Text('Skorları Sil',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('Tüm skorlar silinecek. Emin misin?',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sil',
                          style: TextStyle(color: Color(0xFFEF5350))),
                    ),
                  ],
                ),
              );
              if (confirm == true) _clearScores();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4D96FF)))
          : _scores.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz skor yok.\nİlk oyunu oyna!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scores.length,
                  itemBuilder: (context, index) {
                    final score = _scores[index];
                    final isLast = score == widget.lastScore && index == _scores.indexOf(widget.lastScore);

                    Color rankColor;
                    Widget rankWidget;
                    if (index == 0) {
                      rankColor = const Color(0xFFFFD700); // Altın
                      rankWidget = const Text('🥇', style: TextStyle(fontSize: 22));
                    } else if (index == 1) {
                      rankColor = const Color(0xFFC0C0C0); // Gümüş
                      rankWidget = const Text('🥈', style: TextStyle(fontSize: 22));
                    } else if (index == 2) {
                      rankColor = const Color(0xFFCD7F32); // Bronz
                      rankWidget = const Text('🥉', style: TextStyle(fontSize: 22));
                    } else {
                      rankColor = Colors.white38;
                      rankWidget = Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isLast
                            ? const Color(0xFF4D96FF).withOpacity(0.12)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isLast
                              ? const Color(0xFF4D96FF).withOpacity(0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 36, child: Center(child: rankWidget)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isLast ? 'Sen (Bu oyun)' : 'Oyuncu',
                              style: TextStyle(
                                color: isLast
                                    ? const Color(0xFF4D96FF)
                                    : Colors.white70,
                                fontSize: 14,
                                fontWeight: isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Text(
                            '$score',
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}