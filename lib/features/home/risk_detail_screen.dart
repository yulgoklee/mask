import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/dust_calculator.dart';
import '../../data/models/dust_data.dart';
import '../../data/models/user_profile.dart';
import '../../providers/providers.dart';

/// 나의 위험도 상세 페이지 — 각 조건별 위험도 비교표
class RiskDetailScreen extends ConsumerWidget {
  const RiskDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dustAsync = ref.watch(dustDataProvider);
    final myProfile = ref.watch(profileProvider);
    final myResult = ref.watch(dustCalculationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          '위험도 상세',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: dustAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => const Center(child: Text('데이터를 불러올 수 없어요')),
        data: (dust) {
          if (dust == null) {
            return const Center(child: Text('미세먼지 데이터 없음'));
          }
          final pm25 = dust.pm25Value ?? 0;
          final pm25Grade = _gradeLabel(pm25);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 현재 미세먼지 요약
              _CurrentDustHeader(
                pm25: pm25,
                gradeLabel: pm25Grade,
                myRiskLabel: myResult?.riskLevel.label ?? '-',
                myRiskLevel: myResult?.riskLevel ?? RiskLevel.unknown,
                maskType: myResult?.maskType,
              ),
              const SizedBox(height: 24),

              // 나이대별
              _SectionLabel('나이대별 위험도'),
              const SizedBox(height: 8),
              _AgeGroupTable(dust: dust, myAgeGroup: myProfile.ageGroup),
              const SizedBox(height: 20),

              // 기저질환별
              _SectionLabel('기저질환별 위험도'),
              const SizedBox(height: 8),
              _ConditionTable(dust: dust, myProfile: myProfile),
              const SizedBox(height: 20),

              // 활동 빈도별
              _SectionLabel('활동 빈도별 위험도'),
              const SizedBox(height: 8),
              _ActivityTable(dust: dust, myProfile: myProfile),
              const SizedBox(height: 20),

              // 민감도별
              _SectionLabel('알림 민감도별 위험도'),
              const SizedBox(height: 8),
              _SensitivityTable(dust: dust, myProfile: myProfile),
              const SizedBox(height: 12),

              const Text(
                '* 기저질환 미보유 기준 / 현재 PM2.5 농도 기반 계산입니다.\n'
                '* 위험도는 참고용이며 의료적 진단을 대체하지 않습니다.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _gradeLabel(int pm25) {
    if (pm25 <= 15) return '좋음';
    if (pm25 <= 35) return '보통';
    if (pm25 <= 75) return '나쁨';
    return '매우나쁨';
  }
}

// ── 현재 미세먼지 헤더 ────────────────────────────────────

class _CurrentDustHeader extends StatelessWidget {
  final int pm25;
  final String gradeLabel;
  final String myRiskLabel;
  final RiskLevel myRiskLevel;
  final String? maskType;

  const _CurrentDustHeader({
    required this.pm25,
    required this.gradeLabel,
    required this.myRiskLabel,
    required this.myRiskLevel,
    this.maskType,
  });

  Color get _riskColor {
    switch (myRiskLevel) {
      case RiskLevel.low:      return AppColors.dustGood;
      case RiskLevel.normal:   return AppColors.dustNormal;
      case RiskLevel.warning:  return AppColors.dustBad;
      case RiskLevel.danger:   return AppColors.dustBad;
      case RiskLevel.critical: return AppColors.dustVeryBad;
      case RiskLevel.unknown:  return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_riskColor, _riskColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('현재 초미세먼지(PM2.5)',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$pm25μg/m³  $gradeLabel',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('나의 위험도',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(myRiskLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              if (maskType != null)
                Text(maskType!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 섹션 레이블 ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── 공통 테이블 컨테이너 ──────────────────────────────────

class _TableCard extends StatelessWidget {
  final Widget child;
  const _TableCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }
}

// ── 위험도 뱃지 ───────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final RiskLevel level;
  const _RiskBadge(this.level);

  Color get _color {
    switch (level) {
      case RiskLevel.low:      return AppColors.dustGood;
      case RiskLevel.normal:   return AppColors.dustNormal;
      case RiskLevel.warning:  return AppColors.dustBad;
      case RiskLevel.danger:   return AppColors.dustBad;
      case RiskLevel.critical: return AppColors.dustVeryBad;
      case RiskLevel.unknown:  return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ── 행 위젯 ───────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final String label;
  final RiskLevel level;
  final bool isMe;
  final bool isLast;

  const _TableRow({
    required this.label,
    required this.level,
    this.isMe = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.05) : null,
        border: isLast ? null : const Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                    )),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('나',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
          _RiskBadge(level),
        ],
      ),
    );
  }
}

// ── 나이대별 테이블 ───────────────────────────────────────

class _AgeGroupTable extends StatelessWidget {
  final DustData dust;
  final AgeGroup myAgeGroup;

  const _AgeGroupTable({required this.dust, required this.myAgeGroup});

  RiskLevel _calcRisk(AgeGroup age) {
    final profile = UserProfile(
      ageGroup: age,
      hasCondition: false,
      activityLevel: ActivityLevel.normal,
    );
    return DustCalculator.calculate(profile, dust).riskLevel;
  }

  @override
  Widget build(BuildContext context) {
    final groups = AgeGroup.values;
    return _TableCard(
      child: Column(
        children: groups.asMap().entries.map((e) {
          final i = e.key;
          final age = e.value;
          return _TableRow(
            label: age.label,
            level: _calcRisk(age),
            isMe: age == myAgeGroup,
            isLast: i == groups.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

// ── 기저질환별 테이블 ─────────────────────────────────────

class _ConditionTable extends StatelessWidget {
  final DustData dust;
  final UserProfile myProfile;

  const _ConditionTable({required this.dust, required this.myProfile});

  RiskLevel _calcRisk(bool hasCondition, Severity severity) {
    final profile = UserProfile(
      ageGroup: myProfile.ageGroup,
      hasCondition: hasCondition,
      severity: severity,
      activityLevel: myProfile.activityLevel,
    );
    return DustCalculator.calculate(profile, dust).riskLevel;
  }

  String _myKey() {
    if (!myProfile.hasCondition) return '없음';
    return myProfile.severity.label;
  }

  @override
  Widget build(BuildContext context) {
    final labels  = ['없음', '경증', '중등도', '중증'];
    final hasCs   = [false, true,  true,    true];
    final sevs    = [Severity.mild, Severity.mild, Severity.moderate, Severity.severe];
    final myKey   = _myKey();
    return _TableCard(
      child: Column(
        children: List.generate(labels.length, (i) {
          return _TableRow(
            label: labels[i],
            level: _calcRisk(hasCs[i], sevs[i]),
            isMe: labels[i] == myKey,
            isLast: i == labels.length - 1,
          );
        }),
      ),
    );
  }
}

// ── 활동 빈도별 테이블 ────────────────────────────────────

class _ActivityTable extends StatelessWidget {
  final DustData dust;
  final UserProfile myProfile;

  const _ActivityTable({required this.dust, required this.myProfile});

  RiskLevel _calcRisk(ActivityLevel level) {
    final profile = UserProfile(
      ageGroup: myProfile.ageGroup,
      hasCondition: myProfile.hasCondition,
      severity: myProfile.severity,
      activityLevel: level,
    );
    return DustCalculator.calculate(profile, dust).riskLevel;
  }

  @override
  Widget build(BuildContext context) {
    final levels = ActivityLevel.values;
    return _TableCard(
      child: Column(
        children: levels.asMap().entries.map((e) {
          final i = e.key;
          final level = e.value;
          return _TableRow(
            label: '${level.label} (${level.description})',
            level: _calcRisk(level),
            isMe: level == myProfile.activityLevel,
            isLast: i == levels.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

// ── 민감도별 테이블 ───────────────────────────────────────

class _SensitivityTable extends StatelessWidget {
  final DustData dust;
  final UserProfile myProfile;

  const _SensitivityTable({required this.dust, required this.myProfile});

  RiskLevel _calcRisk(SensitivityLevel sensitivity) {
    final profile = UserProfile(
      ageGroup: myProfile.ageGroup,
      hasCondition: myProfile.hasCondition,
      severity: myProfile.severity,
      activityLevel: myProfile.activityLevel,
      sensitivity: sensitivity,
    );
    return DustCalculator.calculate(profile, dust).riskLevel;
  }

  @override
  Widget build(BuildContext context) {
    final levels = SensitivityLevel.values;
    final labels = ['낮음 (더 높은 농도에서 반응)', '보통', '높음 (더 낮은 농도에서 반응)'];
    return _TableCard(
      child: Column(
        children: levels.asMap().entries.map((e) {
          final i = e.key;
          final level = e.value;
          return _TableRow(
            label: labels[i],
            level: _calcRisk(level),
            isMe: level == myProfile.sensitivity,
            isLast: i == levels.length - 1,
          );
        }).toList(),
      ),
    );
  }
}
