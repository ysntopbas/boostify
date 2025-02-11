import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class BatteryService {
  static final Battery _battery = Battery();
  static const platform = MethodChannel('com.boostify/battery');

  static Future<int> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level;
    } catch (e) {
      return 0;
    }
  }

  static Future<BatteryState> getBatteryState() async {
    try {
      final state = await _battery.batteryState;
      return state;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  static Future<Map<String, dynamic>> getBatteryInfo() async {
    try {
      final temperature = await platform.invokeMethod('getBatteryTemperature');
      final voltage = await platform.invokeMethod('getBatteryVoltage');
      final technology = await platform.invokeMethod('getBatteryTechnology');
      final health = await platform.invokeMethod('getBatteryHealth');
      
      return {
        'temperature': temperature,
        'voltage': voltage,
        'technology': technology,
        'health': health,
      };
    } catch (e) {
      return {};
    }
  }

  static String getBatteryHealthStatus(int health) {
    switch (health) {
      case 2: return 'İyi';
      case 3: return 'Aşırı Isınmış';
      case 4: return 'Hasarlı';
      case 5: return 'Aşırı Voltaj';
      case 6: return 'Bilinmeyen Hata';
      case 7: return 'Kalibre Edilmemiş';
      default: return 'Bilinmiyor';
    }
  }
} 