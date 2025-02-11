import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:boostify/services/system_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:boostify/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RamCleanerScreen extends StatefulWidget {
  const RamCleanerScreen({super.key});

  @override
  State<RamCleanerScreen> createState() => _RamCleanerScreenState();
}

class _RamCleanerScreenState extends State<RamCleanerScreen> {
  bool isCleaningRam = false;
  bool showCleanedStatus = false;
  double ramUsage = 0.7; // Test için %70 başlangıç değeri
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool isCleanButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadRamInfo();
    _loadBannerAd();
    AdService.loadRewardedAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.createBannerAd()
      ..load().then((_) {
        setState(() {
          _isAdLoaded = true;
        });
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadRamInfo() async {
    final ram = await SystemService.getRamUsage();
    setState(() {
      ramUsage = ram;
    });
  }

  Future<void> cleanRam() async {
    if (!isCleanButtonEnabled) return;

    setState(() {
      isCleanButtonEnabled = false;
    });

    try {
      final bool rewardEarned = await AdService.showRewardedAd();
      
      if (rewardEarned) {
        setState(() {
          isCleaningRam = true;
          showCleanedStatus = false;
        });

        // RAM temizleme işlemi
        await SystemService.cleanRam();
        await Future.delayed(const Duration(seconds: 2));
        await _loadRamInfo();

        setState(() {
          isCleaningRam = false;
          showCleanedStatus = true;
        });

        // 3 saniye sonra durumu sıfırla
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            showCleanedStatus = false;
            isCleanButtonEnabled = true;
          });
        }
      } else {
        setState(() {
          isCleanButtonEnabled = true;
        });
      }
    } catch (e) {
      setState(() {
        isCleaningRam = false;
        showCleanedStatus = false;
        isCleanButtonEnabled = true;
      });
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

  Widget _buildStatusIndicator() {
    if (!isCleaningRam && !showCleanedStatus) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isCleaningRam) ...[
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
            'cleaning'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ] else if (showCleanedStatus) ...[
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'cleaned'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ],
    );
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
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
                    const SizedBox(height: 30),
                    _buildStatusIndicator(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: !isCleanButtonEnabled ? null : cleanRam,
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