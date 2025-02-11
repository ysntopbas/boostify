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
import 'package:boostify/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  
  const HomeScreen({
    super.key,
    required this.onThemeChanged,
  });

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
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool isOptimizeButtonEnabled = true;

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

    _loadBannerAd();
    AdService.loadRewardedAd();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd?.dispose();
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

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd()
      ..load().then((_) {
        setState(() {
          _isAdLoaded = true;
        });
      });
  }

  Future<void> optimize() async {
    if (!isOptimizeButtonEnabled) return;
    
    setState(() {
      isOptimizeButtonEnabled = false;
    });

    try {
      final bool rewardEarned = await AdService.showRewardedAd();
      
      if (rewardEarned) {
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
          await SystemService.optimizeSystem();
          await Future.delayed(Duration(seconds: duration));

          // Complete
          final score = await OptimizeService.optimize();
          setState(() {
            systemScore = score / 100;
            currentStep = 4;
            showDoneButton = true;
            isOptimizeButtonEnabled = false; // Buton devre dışı kalsın
          });
        } catch (e) {
          await _resetOptimization();
        }
      } else {
        // Ödül kazanılmadıysa butonu tekrar aktif et
        setState(() {
          isOptimizeButtonEnabled = true;
        });
      }
    } catch (e) {
      // Hata durumunda butonu tekrar aktif et
      setState(() {
        isOptimizeButtonEnabled = true;
      });
    }
  }

  Future<void> _resetOptimization() async {
    await _animationController.reverse();
    setState(() {
      isOptimizing = false;
      currentStep = -1;
      showDoneButton = false;
      isOptimizeButtonEnabled = true; // Butonu tekrar aktif et
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
    return Column(
      children: [
        Container(
          height: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Timeline.tileBuilder(
            theme: TimelineThemeData(
              direction: Axis.horizontal,
              connectorTheme: const ConnectorThemeData(
                thickness: 2.0,
                space: 12.0,
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
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted || isActive ? step.activeIcon : step.icon,
                        color: isCompleted ? Colors.green : isActive ? Colors.blue : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 105,
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
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!showDoneButton) ...[
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'optimizing_status'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'optimized_status'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        if (showDoneButton) ...[
          const SizedBox(height: 16),
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
        ],
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
          children: [
            Expanded(
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
                  const SizedBox(height: 20),
                  if (isOptimizing) ...[
                    _buildOptimizationTimeline(),
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
                                    builder: (context) => SettingsScreen(
                                      onThemeChanged: widget.onThemeChanged,
                                      currentThemeMode: Theme.of(context).brightness == Brightness.dark 
                                        ? ThemeMode.dark 
                                        : ThemeMode.light,
                                    ),
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
                          onPressed: !isOptimizeButtonEnabled ? null : optimize,
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
            if (_isAdLoaded)
              Container(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
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