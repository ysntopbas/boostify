import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

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
      case 2: return 'health_good'.tr();
      case 3: return 'health_overheat'.tr();
      case 4: return 'health_dead'.tr();
      case 5: return 'health_overvoltage'.tr();
      case 6: return 'health_failure'.tr();
      case 7: return 'health_cold'.tr();
      default: return 'unknown'.tr();
    }
  }
} 