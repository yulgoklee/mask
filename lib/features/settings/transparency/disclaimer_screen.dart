import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/design_tokens.dart';
import '../widgets/settings_drill_header.dart';
import '../widgets/s_label.dart';

/// 투명성 — 의료도구 면책
///
/// 클래스명 TransparencyDisclaimerScreen (온보딩 DisclaimerScreen과 충돌 방지)
class TransparencyDisclaimerScreen extends StatelessWidget {
  const TransparencyDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsDrillHeader(
              title: '의료도구 면책',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 타이틀 ───────────────────────────────
                    const Text(
                      '이 앱은\n의료기기가 아니에요.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: DT.text,
                        letterSpacing: -0.52,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: DT.gray,
                          height: 1.65,
                        ),
                        children: [
                          TextSpan(
                            text: '본 앱은 참고용 정보를 제공하는 앱이에요. ',
                          ),
                          TextSpan(
                            text: '진단·처방·치료 목적이 아니에요.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: DT.text,
                            ),
                          ),
                          TextSpan(
                            text: ' 미세먼지 수치와 건강 입력 정보를 조합해 '
                                '개인화된 알림 기준을 계산하고, 외출 판단에 참고할 정보를 제공해요.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 이 앱이 하는 것 ──────────────────────
                    const SLabel('이 앱이 하는 것'),
                    const SizedBox(height: 8),
                    const _DiscBullet(
                        '에어코리아 실시간 데이터를 가져와 보여줘요.'),
                    const _DiscBullet(
                        '건강 정보 입력 기반으로 개인 임계치(T_final)를 계산해요.'),
                    const _DiscBullet(
                        '임계치를 초과하면 마스크 착용을 알려줘요.'),
                    const SizedBox(height: 24),

                    // ── 이 앱이 하지 않는 것 ─────────────────
                    const SLabel('이 앱이 하지 않는 것'),
                    const SizedBox(height: 8),
                    const _DiscBullet('질환을 진단하거나 치료를 권고하지 않아요.',
                        stress: true),
                    const _DiscBullet('의료 전문가의 판단을 대체하지 않아요.',
                        stress: true),
                    const _DiscBullet('응급 상황에 대응하는 기능이 없어요.',
                        stress: true),
                    const SizedBox(height: 28),

                    // ── 강조 박스 ────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DT.text.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '호흡 곤란, 흉통, 심한 기침이 있다면',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DT.text,
                              letterSpacing: -0.14,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '앱을 사용하지 말고 즉시 의료 도움을 받으세요. '
                            '119에 신고하거나 가까운 응급실을 방문하세요.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: DT.gray,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// bullet (5dp 원 + 텍스트)
class _DiscBullet extends StatelessWidget {
  final String text;
  final bool stress;

  const _DiscBullet(this.text, {this.stress = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stress ? DT.text : DT.gray2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: stress ? FontWeight.w600 : FontWeight.w500,
                color: stress ? DT.text : DT.gray,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
