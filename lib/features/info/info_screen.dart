import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '미세먼지 정보',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _GradeTable(),
                const SizedBox(height: 24),
                _MaskGuide(),
                const SizedBox(height: 24),
                _HealthTips(),
                const SizedBox(height: 24),
                _SourceReferences(),
                const SizedBox(height: 16),
                const Text(
                  '* 본 앱은 참고용 정보를 제공합니다. 의료적 진단이나 처방을 대체하지 않습니다.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // 광고 배너 — P4: AdMob 비활성화
          // const SafeArea(
          //   top: false,
          //   child: AdBannerWidget(),
          // ),
        ],
      ),
    );
  }
}

class _GradeTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const grades = [
      {'grade': '좋음', 'pm25': '0~15', 'pm10': '0~30', 'color': AppColors.dustGood},
      {'grade': '보통', 'pm25': '16~35', 'pm10': '31~80', 'color': AppColors.dustNormal},
      {'grade': '나쁨', 'pm25': '36~75', 'pm10': '81~150', 'color': AppColors.dustBad},
      {'grade': '매우나쁨', 'pm25': '76 이상', 'pm10': '151 이상', 'color': AppColors.dustVeryBad},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '미세먼지 등급 기준',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          '단위: μg/m³',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('등급',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13))),
                    Expanded(
                        flex: 2,
                        child: Text('PM2.5',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13))),
                    Expanded(
                        flex: 2,
                        child: Text('PM10',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13))),
                  ],
                ),
              ),
              ...grades.asMap().entries.map((e) {
                final i = e.key;
                final g = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: i < grades.length - 1
                        ? const Border(
                            bottom: BorderSide(color: AppColors.divider))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: g['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(g['grade'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: g['color'] as Color,
                                )),
                          ],
                        ),
                      ),
                      Expanded(
                          flex: 2,
                          child: Text(g['pm25'] as String,
                              style: const TextStyle(fontSize: 13))),
                      Expanded(
                          flex: 2,
                          child: Text(g['pm10'] as String,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaskGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const masks = [
      {
        'name': 'KF94',
        'desc': '94% 이상 차단. 나쁨~매우나쁨 시 권장.',
        'icon': Icons.masks,
      },
      {
        'name': 'KF80',
        'desc': '80% 이상 차단. 보통~나쁨 시 사용 가능.',
        'icon': Icons.masks_outlined,
      },
      {
        'name': '일반 마스크',
        'desc': '미세먼지 차단 효과 없음. 비말 차단용.',
        'icon': Icons.do_not_disturb_alt_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '마스크 종류',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...masks.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(m['icon'] as IconData,
                        color: AppColors.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['name'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            m['desc'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _HealthTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tips = [
      '미세먼지가 나쁠 때는 환기를 줄이고 공기청정기를 활용하세요.',
      '야외 운동 시 미세먼지가 나쁘면 실내 운동으로 대체하세요.',
      '외출 후 귀가 시 손을 씻고 세안을 꼭 하세요.',
      '기저질환자·어린이·고령자는 건강한 성인보다 더 민감하게 반응해요.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '건강 관리 팁',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: tips
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(color: AppColors.primary)),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SourceReferences extends StatelessWidget {
  static const _sources = [
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
      'WHO — 대기오염 가이드라인 2021',
      'WHO Global Air Quality Guidelines (PM2.5 / PM10)',
      'https://www.who.int/publications/i/item/9789240034228',
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
    (
      'Asthma Control Test (ACT)',
      'ATS / 천식 자가 평가 도구',
      'https://www.thoracic.org/members/assemblies/assemblies/srn/questionaires/act.php',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('📚', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '근거 자료',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '본 앱의 임계치·페르소나 분류는 다음 의학·환경 가이드라인을 참고합니다.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._sources.map((s) {
            final (title, subtitle, _) = s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
