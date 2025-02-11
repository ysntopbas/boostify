import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';

class AdService {
  static String get bannerAdUnitId {
    // Test reklamları için
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  static String get interstitialAdUnitId {
    // Test reklamları için
    return 'ca-app-pub-3940256099942544/1033173712';
  }

  static String get rewardedAdUnitId {
    // Test reklamları için
    return 'ca-app-pub-3940256099942544/5224354917';
  }

  static Future<void> initAds() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;

  static Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
        },
      ),
    );
  }

  static Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd?.show();
    }
  }

  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  static Future<bool> showRewardedAd() async {
    if (_rewardedAd != null) {
      Completer<bool> rewardCompleter = Completer<bool>();
      bool hasReward = false;
      
      try {
        _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
            rewardCompleter.complete(hasReward);
            loadRewardedAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _rewardedAd = null;
            rewardCompleter.complete(false);
            loadRewardedAd();
          },
        );

        await _rewardedAd?.show(
          onUserEarnedReward: (_, reward) {
            print('User earned reward: ${reward.amount} ${reward.type}');
            hasReward = true;
          },
        );
        
        return await rewardCompleter.future;
      } catch (e) {
        if (!rewardCompleter.isCompleted) {
          rewardCompleter.complete(false);
        }
        return false;
      }
    }
    return false;
  }

  static void disposeAds() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
} 