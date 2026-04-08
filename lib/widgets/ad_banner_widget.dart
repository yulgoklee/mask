import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob 배너 광고 위젯 (모바일 전용, 웹에서는 빈 위젯)
class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return const _MobileAdBanner();
  }
}

class _MobileAdBanner extends StatefulWidget {
  const _MobileAdBanner();

  @override
  State<_MobileAdBanner> createState() => _MobileAdBannerState();
}

class _MobileAdBannerState extends State<_MobileAdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // 테스트 ID
      : 'ca-app-pub-2943697287082336/8957783957'; // 실제 ID

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
