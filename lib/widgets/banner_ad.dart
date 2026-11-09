import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// One small banner ad. ByeLui is free and has no premium subscription.
/// Never use Android production ad units for iOS.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  Timer? _retryTimer;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  String get _adUnitId {
    const production = bool.fromEnvironment('dart.vm.product');
    if (Platform.isIOS) {
      if (!production) return 'ca-app-pub-3940256099942544/2934735716';
      // ByeLui iOS production banner ad unit (separate from the AdMob app ID).
      return 'ca-app-pub-6586968137131686/6917777380';
    }
    if (!production) return 'ca-app-pub-3940256099942544/6300978111';
    return 'ca-app-pub-6586968137131686/1306249287';
  }

  void _loadBannerAd() {
    final unitId = _adUnitId;
    if (!mounted) return;

    _retryTimer?.cancel();
    _retryTimer = null;
    _isAdLoaded = false;

    // Never retain a failed banner while loading its replacement.
    _bannerAd?.dispose();
    _bannerAd = null;

    late final BannerAd banner;
    banner = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !identical(_bannerAd, banner)) {
            ad.dispose();
            return;
          }
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || !identical(_bannerAd, banner)) return;
          setState(() {
            _isAdLoaded = false;
            _bannerAd = null;
          });
          _retryTimer?.cancel();
          _retryTimer = Timer(const Duration(seconds: 30), () {
            if (mounted) _loadBannerAd();
          });
        },
      ),
    );
    _bannerAd = banner;
    banner.load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isAdLoaded || ad == null) return const SizedBox(height: 50);

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
