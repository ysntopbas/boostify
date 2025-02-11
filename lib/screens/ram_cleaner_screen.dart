import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:boostify/services/system_service.dart';
import 'package:easy_localization/easy_localization.dart';

class RamCleanerScreen extends StatefulWidget {
  const RamCleanerScreen({super.key});

  @override
  State<RamCleanerScreen> createState() => _RamCleanerScreenState();
}

class _RamCleanerScreenState extends State<RamCleanerScreen> {
  bool isCleaningRam = false;
  double ramUsage = 0.7; // Test için %70 başlangıç değeri

  @override
  void initState() {
    super.initState();
    _loadRamInfo();
  }

  Future<void> _loadRamInfo() async {
    final ram = await SystemService.getRamUsage();
    setState(() {
      ramUsage = ram;
    });
  }

  Future<void> cleanRam() async {
    setState(() => isCleaningRam = true);
    try {
      await SystemService.cleanRam();
      await _loadRamInfo();
    } finally {
      setState(() => isCleaningRam = false);
    }
  }

  Color _getRamStatusColor() {
    final percentage = ramUsage * 100;
    if (percentage <= 30) return Colors.green;
    if (percentage <= 70) return Colors.orange;
    return Colors.red;
  }

  String _getRamStatusText() {
    final percentage = ramUsage * 100;
    if (percentage <= 30) return 'ram_usage_low'.tr();
    if (percentage <= 70) return 'ram_usage_normal'.tr();
    return 'ram_usage_high'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ram_cleaner'.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
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
              percent: ramUsage,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ram_usage'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(ramUsage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getRamStatusColor(),
                    ),
                  ),
                  Text(
                    _getRamStatusText(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _getRamStatusColor(),
                    ),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: _getRamStatusColor(),
              backgroundColor: Colors.blue.withOpacity(0.2),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: isCleaningRam ? null : cleanRam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getRamStatusColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  isCleaningRam ? 'cleaning'.tr() : 'clean_ram'.tr(),
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