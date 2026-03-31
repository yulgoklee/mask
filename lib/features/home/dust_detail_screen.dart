import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/dust_standards.dart';

/// 미세먼지 / 초미세먼지 세부 정보 화면
class DustDetailScreen extends StatelessWidget {
  final int? pm10Value;
  final int? pm25Value;
  final DustGrade pm10Grade;
  final DustGrade pm25Grade;

  const DustDetailScreen({
    super.key,
    required this.pm10Value,
    required this.pm25Value,
    required this.pm10Grade,
    required this.pm25Grade,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '미세먼지 세부정보',
          style: TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 현재 측정값 카드
          _CurrentValueCard(
            pm10Value: pm10Value,
            pm25Value: pm25Value,
            pm10Grade: pm10Grade,
            pm25Grade: pm25Grade,
          ),
          const SizedBox(height: 24),

          // PM2.5 기준표
          _SectionTitle('초미세먼지 (PM2.5) 기준'),
          const SizedBox(height: 8),
          const _ThresholdTable(
            isPm25: true,
            rows: [
              _ThresholdRow('좋음', '0 ~ 15', AppColors.dustGood),
              _ThresholdRow('보통', '16 ~ 35', AppColors.dustNormal),
              _ThresholdRow('나쁨', '36 ~ 75', AppColors.dustBad),
              _ThresholdRow('매우나쁨', '76 이상', AppColors.dustVeryBad),
            ],
          ),
          const SizedBox(height: 20),

          // PM10 기준표
          _SectionTitle('미세먼지 (PM10) 기준'),
          const SizedBox(height: 8),
          const _ThresholdTable(
            isPm25: false,
            rows: [
              _ThresholdRow('좋음', '0 ~ 30', AppColors.dustGood),
              _ThresholdRow('보통', '31 ~ 80', AppColors.dustNormal),
              _ThresholdRow('나쁨', '81 ~ 150', AppColors.dustBad),
              _ThresholdRow('매우나쁨', '151 이상', AppColors.dustVeryBad),
            ],
          ),
          const SizedBox(height: 20),

          // 건강 영향 안내
          _SectionTitle('등급별 건강 영향'),
          const SizedBox(height: 8),
          const _HealthGuideCard(),
          const SizedBox(height: 12),
          const Text(
            '* 단위: μg/m³ (마이크로그램/세제곱미터)\n'
            '* 출처: 환경부 / 에어코리아 대기환경기준',
            style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── 현재 측정값 카드 ─────────────────────────────────────

class _CurrentValueCard extends StatelessWidget {
  final int? pm10Value;
  final int? pm25Value;
  final DustGrade pm10Grade;
  final DustGrade pm25Grade;

  const _CurrentValueCard({
    required this.pm10Value,
    required this.pm25Value,
    required this.pm10Grade,
    required this.pm25Grade,
  });

  Color _gradeColor(DustGrade g) => g.color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('현재 측정값',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ValueItem(
                label: '미세먼지 (PM10)',
                value: pm10Value,
                grade: pm10Grade,
                color: _gradeColor(pm10Grade),
              )),
              const SizedBox(width: 12),
              Expanded(child: _ValueItem(
                label: '초미세먼지 (PM2.5)',
                value: pm25Value,
                grade: pm25Grade,
                color: _gradeColor(pm25Grade),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueItem extends StatelessWidget {
  final String label;
  final int? value;
  final DustGrade grade;
  final Color color;

  const _ValueItem({
    required this.label,
    required this.value,
    required this.grade,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            value != null ? '$value μg/m³' : '- μg/m³',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(grade.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 제목 ────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3));
  }
}

// ── 기준표 ────────────────────────────────────────────────

class _ThresholdRow {
  final String grade;
  final String range;
  final Color color;
  const _ThresholdRow(this.grade, this.range, this.color);
}

class _ThresholdTable extends StatelessWidget {
  final bool isPm25;
  final List<_ThresholdRow> rows;
  const _ThresholdTable({required this.isPm25, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.divider.withOpacity(0.5),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text('등급',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('농도 범위 (μg/m³)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          // 데이터 행
          ...rows.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: i < rows.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.divider, width: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: row.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(row.grade,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: row.color)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(row.range,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ── 건강 영향 안내 ────────────────────────────────────────

class _HealthGuideCard extends StatelessWidget {
  const _HealthGuideCard();

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.dustGood, AppColors.dustNormal, AppColors.dustBad, AppColors.dustVeryBad];
    final grades = ['좋음', '보통', '나쁨', '매우나쁨'];
    final descs  = [
      '민감군도 야외활동 가능. 일반인은 모든 활동 가능.',
      '민감군은 장시간 야외활동 자제. 일반인은 정상 활동 가능.',
      '민감군은 외출 자제. 일반인도 장시간 야외활동 자제 권고.',
      '모든 사람 외출 자제. 부득이한 경우 KF94 마스크 착용.',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(4, (i) {
          final color = colors[i];
          final grade = grades[i];
          final desc  = descs[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: i < 3
                  ? const Border(
                      bottom: BorderSide(color: AppColors.divider, width: 0.5))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(8)),
                  child: Text(grade,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(desc,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4)),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
