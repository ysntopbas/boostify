import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class OptimizeService {
  static const String _lastOptimizeTimeKey = 'last_optimize_time';
  static const String _scoreKey = 'optimize_score';
  static const String _optimizeCountKey = 'optimize_count';
  static const int _checkInterval = 600; 
  static const double _minScore = 70.0;
  static const double _maxScore = 100.0;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_scoreKey)) {
      await prefs.setDouble(_scoreKey, _maxScore);
      await prefs.setInt(_lastOptimizeTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_optimizeCountKey, 0);
    }
  }

  static Future<double> getScore() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(_lastOptimizeTimeKey) ?? DateTime.now().millisecondsSinceEpoch;
    final currentScore = prefs.getDouble(_scoreKey) ?? _maxScore;

    // Son optimize'dan bu yana geçen süreyi hesapla
    final timeDifference = DateTime.now().millisecondsSinceEpoch - lastTime;
    final intervals = (timeDifference / 1000) ~/ _checkInterval;

    if (intervals > 0) {
      print('Geçen süre: ${timeDifference / 1000} saniye');
      print('Düşülecek puan: $intervals');
      
      // Her interval için 1 puan düş
      double newScore = currentScore - intervals.toDouble();
      // Minimum skorun altına düşmesini engelle
      newScore = newScore.clamp(_minScore, _maxScore);
      
      // Yeni skoru kaydet
      await prefs.setDouble(_scoreKey, newScore);
      
      // Son optimize zamanını güncelle
      await prefs.setInt(_lastOptimizeTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      return newScore;
    }

    return currentScore;
  }

  static Future<double> optimize() async {
    final prefs = await SharedPreferences.getInstance();
    final currentScore = prefs.getDouble(_scoreKey) ?? _maxScore;
    double newScore;

    if (currentScore >= 90 && currentScore < 100) {
      // 95-99 arası değerler için direkt 100
      newScore = 100;
    } else {
      final optimizeCount = prefs.getInt(_optimizeCountKey) ?? 0;
      if (optimizeCount == 0) {
        // İlk optimize: 95-100 arası random
        newScore = 95 + Random().nextDouble() * 5;
      } else {
        // İkinci ve sonraki optimize: 100
        newScore = 100;
      }
      await prefs.setInt(_optimizeCountKey, optimizeCount + 1);
    }

    // Yeni skoru ve optimize zamanını kaydet
    await prefs.setDouble(_scoreKey, newScore);
    await prefs.setInt(_lastOptimizeTimeKey, DateTime.now().millisecondsSinceEpoch);

    return newScore;
  }

  static Future<void> resetOptimizeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_optimizeCountKey, 0);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}