import 'dart:async';
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

  // TODO: replace with ByeLui's real ad unit IDs once registered in AdMob.
  String get _adUnitId {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return 'ca-app-pub-3940256099942544/6300978111'; // placeholder — swap for prod unit
    } else {
      return 'ca-app-pub-3940256099942544/6300978111'; // Google test banner unit
    }
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
