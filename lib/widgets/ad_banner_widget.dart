import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  // 모바일 빌드 시 google_mobile_ads 활성화
  // BannerAd? _bannerAd;
  // bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    // TODO: 모바일 배포 시 google_mobile_ads 코드 활성화
    return const SizedBox.shrink();
  }
}
