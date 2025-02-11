import 'package:flutter/services.dart';

class AndroidService {
  static const platform = MethodChannel('com.boostify/system');

  static Future<double> getRamUsage() async {
    try {
      final result = await platform.invokeMethod('getRamUsage');
      return result as double;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<void> cleanRam() async {
    try {
      await platform.invokeMethod('cleanRam');
    } catch (e) {
      // Hata durumunda işlem yapılmayacak
    }
  }
} 