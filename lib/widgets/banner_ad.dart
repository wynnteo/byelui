import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/data_service.dart';

/// Bottom banner ad, same placement pattern as MyLui's BannerAdWidget.
/// Hides itself entirely for premium/ad-free users.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final bool _isPremium = DataService().isPremium;

  @override
  void initState() {
    super.initState();
    if (!_isPremium) {
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    if (_adUnitId.isEmpty) return; // iOS production needs its own AdMob banner ID.
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _isAdLoaded = false);
          Timer(const Duration(seconds: 30), () {
            if (mounted && !_isPremium) _loadBannerAd();
          });
        },
      ),
    );
    _bannerAd!.load();
  }

  String get _adUnitId {
    const production = bool.fromEnvironment('dart.vm.product');
    if (Platform.isIOS) {
      if (!production) return 'ca-app-pub-3940256099942544/2934735716';
      // Do not serve ads using the Android ad unit on iOS.
      // Pass --dart-define=BYELUI_IOS_AD_UNIT_ID=<actual iOS banner ID>
      // after creating ByeLui's iOS app in AdMob.
      return const String.fromEnvironment('BYELUI_IOS_AD_UNIT_ID');
    }
    if (!production) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-6586968137131686/1306249287'; // Confirm this is the active Android banner unit.
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) return const SizedBox.shrink();
    if (!_isAdLoaded || _bannerAd == null) return const SizedBox(height: 50);

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
