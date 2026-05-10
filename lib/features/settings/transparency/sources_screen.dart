import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/design_tokens.dart';
import '../widgets/settings_drill_header.dart';
import '../widgets/s_label.dart';
import '../widgets/s_ext_icon.dart';

/// 투명성 — 참고 자료·가이드라인
///
/// info_screen _SourceReferences 데이터 재활용.
/// 그룹: 1차 자료 / 임상 가이드라인 / 데이터 출처
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  // (그룹, 제목, 설명, URL)
  static const _group1 = [
    (
      'WHO — 대기오염 가이드라인 2021',
      'WHO Global Air Quality Guidelines (PM2.5 / PM10)',
      'https://www.who.int/publications/i/item/9789240034228',
    ),
    (
      '환경부 미세먼지 기준',
      '한국 환경부 미세먼지 예보 기준 (PM2.5 35㎍/㎥ 기준)',
      'https://www.airkorea.or.kr',
    ),
  ];

  static const _group2 = [
    (
      'ARIA — 알레르기성 비염 가이드라인',
      'Allergic Rhinitis and its Impact on Asthma (JACI 2019)',
      'https://www.jacionline.org/article/S0091-6749(19)31187-X/fulltext',
    ),
    (
      'ATS — 운동 유발 기관지수축 가이드라인',
      'American Thoracic Society Clinical Practice Guideline (2013)',
      'https://www.atsjournals.org/doi/full/10.1164/rccm.201303-0437ST',
    ),
    (
      '대한천식알레르기학회 (KAAACI)',
      '한국 알레르기 비염 진단 기준',
      'https://www.allergy.or.kr',
    ),
    (
      'GOLD — COPD 가이드라인',
      'Global Initiative for Chronic Obstructive Lung Disease',
      'https://goldcopd.org',
    ),
  ];

  static const _group3 = [
    (
      '에어코리아 (한국환경공단)',
      '실시간 대기오염 측정 데이터 API',
      'https://www.airkorea.or.kr',
    ),
  ];

  static Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsDrillHeader(
              title: '참고 자료',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '이 앱이 따르는 자료예요. 모두 공개되어 있어요.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: DT.gray,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const SLabel('1차 자료'),
                    ..._group1.map((s) => _RefRow(
                          title: s.$1,
                          desc: s.$2,
                          url: s.$3,
                          onTap: () => _open(s.$3),
                        )),
                    const SLabel('임상 가이드라인'),
                    ..._group2.map((s) => _RefRow(
                          title: s.$1,
                          desc: s.$2,
                          url: s.$3,
                          onTap: () => _open(s.$3),
                        )),
                    const SLabel('데이터 출처'),
                    ..._group3.map((s) => _RefRow(
                          title: s.$1,
                          desc: s.$2,
                          url: s.$3,
                          onTap: () => _open(s.$3),
                        )),
                    const SizedBox(height: 24),
                    const Text(
                      '외부 사이트로 이동해요. 영어 자료 포함.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: DT.gray2,
                      ),
                    ),
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

class _RefRow extends StatelessWidget {
  final String title;
  final String desc;
  final String url;
  final VoidCallback onTap;

  const _RefRow({
    required this.title,
    required this.desc,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DT.text,
                      letterSpacing: -0.14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DT.gray,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: SExtIcon(),
            ),
          ],
        ),
      ),
    );
  }
}
