import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class OptimizeService {
  static const String _lastOptimizeTimeKey = 'last_optimize_time';
  static const String _scoreKey = 'optimize_score';
  static const String _optimizeCountKey = 'optimize_count';
  static const int _checkInterval = 6; // 10 dakika (saniye cinsinden)
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
    final lastOptimizeTime = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_lastOptimizeTimeKey) ?? DateTime.now().millisecondsSinceEpoch
    );
    final currentScore = prefs.getDouble(_scoreKey) ?? _maxScore;

    // Son optimize'dan bu yana geçen 10 dakikaları hesapla
    final timeDifference = DateTime.now().difference(lastOptimizeTime).inSeconds;
    final intervals = timeDifference ~/ _checkInterval;
    
    if (intervals > 0) {
      // Her 10 dakika için 1 puan düş
      double newScore = currentScore - intervals.toDouble();
      // Minimum skorun altına düşmesini engelle
      newScore = newScore.clamp(_minScore, _maxScore);
      
      // Yeni skoru kaydet
      await prefs.setDouble(_scoreKey, newScore);
      return newScore;
    }

    return currentScore;
  }

  static Future<double> optimize() async {
    final prefs = await SharedPreferences.getInstance();
    final optimizeCount = prefs.getInt(_optimizeCountKey) ?? 0;
    double newScore;

    if (optimizeCount == 0) {
      // İlk optimize: 95-100 arası random
      newScore = 95 + Random().nextDouble() * 5;
    } else {
      // İkinci ve sonraki optimize: 100
      newScore = 100;
    }

    await prefs.setDouble(_scoreKey, newScore);
    await prefs.setInt(_lastOptimizeTimeKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_optimizeCountKey, optimizeCount + 1);

    return newScore;
  }

  static Future<void> resetOptimizeCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_optimizeCountKey, 0);
  }
} 