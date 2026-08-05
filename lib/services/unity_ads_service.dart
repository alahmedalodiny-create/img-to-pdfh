import 'dart:io';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../config/ads_config.dart';

class UnityAdsService {
  static bool _isInitialized = false;
  static bool _isAdReady = false;
  static Function? _onAdComplete;
  static Function? _onAdFailed;
  static int _adCount = 0;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await UnityAds.init(
        gameId: Platform.isAndroid 
            ? AdsConfig.gameIdAndroid 
            : AdsConfig.gameIdIOS,
        testMode: true,
        onComplete: () {
          _isInitialized = true;
          print('Unity Ads initialized');
          loadAd();
        },
        onFailed: (error, message) {
          print('Unity Ads init failed: $error - $message');
        },
      );
    } catch (e) {
      print('Unity Ads init error: $e');
    }
  }

  static Future<void> loadAd() async {
    if (!_isInitialized) return;

    try {
      await UnityAds.load(
        placementId: Platform.isAndroid 
            ? AdsConfig.rewardedAdUnitIdAndroid 
            : AdsConfig.rewardedAdUnitIdIOS,
        onComplete: (placementId) {
          _isAdReady = true;
          print('Ad loaded: $placementId');
        },
        onFailed: (placementId, error, message) {
          _isAdReady = false;
          print('Ad load failed: $placementId - $error');
        },
      );
    } catch (e) {
      print('Load ad error: $e');
    }
  }

  static bool get isAdReady => _isAdReady;

  static Future<void> showAd({
    required Function onComplete,
    required Function onFailed,
  }) async {
    _onAdComplete = onComplete;
    _onAdFailed = onFailed;
    _adCount = 0;

    if (!_isInitialized || !_isAdReady) {
      onFailed();
      return;
    }

    await _showSingleAd();
  }

  static Future<void> _showSingleAd() async {
    try {
      await UnityAds.showVideoAd(
        placementId: Platform.isAndroid 
            ? AdsConfig.rewardedAdUnitIdAndroid 
            : AdsConfig.rewardedAdUnitIdIOS,
        onStart: (placementId) => print('Ad started: $placementId'),
        onClick: (placementId) => print('Ad clicked: $placementId'),
        onSkipped: (placementId) {
          print('Ad skipped: $placementId');
          _onAdFailed?.call();
        },
        onComplete: (placementId) {
          print('Ad completed: $placementId');
          _adCount++;
          if (_adCount >= 2) {
            _onAdComplete?.call();
          } else {
            loadAd().then((_) {
              Future.delayed(const Duration(milliseconds: 500), () {
                _showSingleAd();
              });
            });
          }
        },
        onFailed: (placementId, error, message) {
          print('Ad show failed: $placementId - $error');
          _onAdFailed?.call();
        },
      );
    } catch (e) {
      print('Show ad error: $e');
      _onAdFailed?.call();
    }
  }
}
