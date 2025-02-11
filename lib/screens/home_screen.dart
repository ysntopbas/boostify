import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:boostify/services/system_service.dart';
import 'package:boostify/services/battery_service.dart';
import 'package:boostify/screens/ram_cleaner_screen.dart';
import 'package:boostify/screens/battery_info_screen.dart';
import 'package:boostify/screens/settings_screen.dart';
import 'package:boostify/services/optimize_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isOptimizing = false;
  double systemScore = 1.0;
  int batteryLevel = 0;
  bool isCharging = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    final battery = await BatteryService.getBatteryLevel();
    final batteryState = await BatteryService.getBatteryState();
    final score = await OptimizeService.getScore();
    
    setState(() {
      systemScore = score / 100;
      batteryLevel = battery;
      isCharging = batteryState == BatteryState.charging;
    });
  }

  Future<void> optimize() async {
    setState(() => isOptimizing = true);
    try {
      await SystemService.clearCache();
      await SystemService.cleanRam();
      final score = await OptimizeService.optimize();
      setState(() {
        systemScore = score / 100;
      });
    } finally {
      setState(() => isOptimizing = false);
    }
  }

  Color _getScoreColor() {
    final score = systemScore * 100;
    if (score >= 85) return Colors.green;
    if (score >= 75) return Colors.blue;
    if (score >= 70) return Colors.orange.shade400;
    return Colors.red;
  }

  String _getScoreText() {
    final score = systemScore * 100;
    if (score >= 90) return 'excellent'.tr();
    if (score >= 70) return 'good'.tr();
    if (score >= 50) return 'average'.tr();
    return 'critical'.tr();
  }

  Widget _buildCircularButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: color.withOpacity(0.1),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 150.0,
              lineWidth: 15.0,
              animation: true,
              animationDuration: 1000,
              percent: systemScore,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(systemScore * 100).toInt()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreText(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: _getScoreColor(),
                    ),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: _getScoreColor(),
              backgroundColor: Colors.blue.withOpacity(0.2),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircularButton(
                    icon: Icons.memory,
                    label: 'RAM',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RamCleanerScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCircularButton(
                    icon: isCharging ? Icons.battery_charging_full : Icons.battery_full,
                    label: '$batteryLevel%',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BatteryInfoScreen(),
                        ),
                      );
                    },
                  ),
                  _buildCircularButton(
                    icon: Icons.settings,
                    label: 'settings'.tr(),
                    color: Colors.grey,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: isOptimizing ? null : optimize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  isOptimizing ? 'cleaning'.tr() : 'optimization'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 