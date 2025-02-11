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
import 'package:timelines_plus/timelines_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool isOptimizing = false;
  int currentStep = 0;
  double systemScore = 1.0;
  int batteryLevel = 0;
  bool isCharging = false;
  bool showDoneButton = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<OptimizeStep> optimizeSteps = [
    OptimizeStep(
      icon: Icons.memory_outlined,
      activeIcon: Icons.memory,
      optimizingText: 'cpu_optimizing',
      optimizedText: 'cpu_optimized',
    ),
    OptimizeStep(
      icon: Icons.storage_outlined,
      activeIcon: Icons.storage,
      optimizingText: 'ram_optimizing',
      optimizedText: 'ram_optimized',
    ),
    OptimizeStep(
      icon: Icons.battery_alert_outlined,
      activeIcon: Icons.battery_full,
      optimizingText: 'battery_optimizing',
      optimizedText: 'battery_optimized',
    ),
    OptimizeStep(
      icon: Icons.cached_outlined,
      activeIcon: Icons.cached,
      optimizingText: 'cache_optimizing',
      optimizedText: 'cache_optimized',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.15),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  int _getOptimizeDuration() {
    final score = systemScore * 100;
    if (score >= 90) return 1;
    if (score >= 80) return 2;
    return 3;
  }

  Future<void> optimize() async {
    setState(() {
      isOptimizing = true;
      currentStep = 0;
      showDoneButton = false;
    });

    await _animationController.forward();
    final duration = _getOptimizeDuration();

    try {
      // CPU Optimization
      setState(() => currentStep = 0);
      await Future.delayed(Duration(seconds: duration));

      // RAM Optimization
      setState(() => currentStep = 1);
      await SystemService.cleanRam();
      await Future.delayed(Duration(seconds: duration));

      // Battery Optimization
      setState(() => currentStep = 2);
      await Future.delayed(Duration(seconds: duration));

      // Cache Optimization
      setState(() => currentStep = 3);
      await SystemService.clearCache();
      await Future.delayed(Duration(seconds: duration));

      // Complete
      final score = await OptimizeService.optimize();
      setState(() {
        systemScore = score / 100;
        currentStep = 4;
        showDoneButton = true;
      });

    } catch (e) {
      await _resetOptimization();
    }
  }

  Future<void> _resetOptimization() async {
    await _animationController.reverse();
    setState(() {
      isOptimizing = false;
      currentStep = -1;
      showDoneButton = false;
    });
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

  Widget _buildOptimizationTimeline() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Timeline.tileBuilder(
        theme: TimelineThemeData(
          direction: Axis.horizontal,
          connectorTheme: const ConnectorThemeData(
            thickness: 2.0,
          ),
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemCount: optimizeSteps.length,
          contentsBuilder: (_, index) {
            final step = optimizeSteps[index];
            final isActive = currentStep == index;
            final isCompleted = currentStep > index || (showDoneButton && index == optimizeSteps.length - 1);
            
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted || isActive ? step.activeIcon : step.icon,
                    color: isCompleted ? Colors.green : isActive ? Colors.blue : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 100,
                    child: Text(
                      (isActive ? step.optimizingText : step.optimizedText).tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.green : isActive ? Colors.blue : Colors.grey,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
          indicatorBuilder: (_, index) {
            final isActive = currentStep == index;
            final isCompleted = currentStep > index || (showDoneButton && index == optimizeSteps.length - 1);
            
            return DotIndicator(
              size: 20,
              color: isCompleted ? Colors.green : isActive ? Colors.blue : Colors.grey.shade300,
              child: isActive && !showDoneButton
                  ? const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
            );
          },
          connectorBuilder: (_, index, __) {
            final isCompleted = currentStep > index || (showDoneButton && index == optimizeSteps.length - 1);
            return SolidLineConnector(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
            );
          },
        ),
      ),
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
          children: [
            const SizedBox(height: 100),
            SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: CircularPercentIndicator(
                  radius: 110.0,
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
              ),
            ),
            const SizedBox(height: 30),
            if (isOptimizing) ...[
              _buildOptimizationTimeline(),
              if (showDoneButton) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _resetOptimization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'done'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ] else ...[
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
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
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OptimizeStep {
  final IconData icon;
  final IconData activeIcon;
  final String optimizingText;
  final String optimizedText;

  OptimizeStep({
    required this.icon,
    required this.activeIcon,
    required this.optimizingText,
    required this.optimizedText,
  });
} 