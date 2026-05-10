import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/design_tokens.dart';
import '../widgets/settings_drill_header.dart';

/// 투명성 — 한계와 책임
class LimitsScreen extends StatelessWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsDrillHeader(
              title: '한계와 책임',
              onBack: () => context.pop(),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이 앱은 에어코리아 공개 데이터와 개인이 입력한 건강 정보를 조합해 참고용 알림을 제공해요.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: DT.gray,
                        height: 1.65,
                      ),
                    ),
                    SizedBox(height: 20),
                    _LimitItem(
                      title: '측정소 위치의 한계',
                      body: '에어코리아 측정소는 특정 지점에 설치되어 있어요. '
                          '내 실제 위치와 거리가 있어 수치가 다를 수 있어요.',
                    ),
                    _LimitItem(
                      title: '기상 조건의 변동성',
                      body: '바람, 강수량, 계절 변화에 따라 미세먼지 농도는 시간 단위로 급변할 수 있어요. '
                          '앱이 제공하는 수치는 폴링 시점 기준이에요.',
                    ),
                    _LimitItem(
                      title: '개인 민감도의 다양성',
                      body: '같은 농도에서도 개인의 건강 상태, 컨디션, 복용 약물에 따라 반응이 달라요. '
                          'T_final은 입력된 건강 정보를 기반으로 한 참고치예요.',
                    ),
                    _LimitItem(
                      title: '의료 판단의 근거가 아님',
                      body: '이 앱의 수치와 알림은 참고용이에요. '
                          '호흡기 증상, 건강 이상 판단, 치료 결정은 반드시 의료 전문가와 상담하세요.',
                      stress: true,
                      last: true,
                    ),
                    SizedBox(height: 24),
                    Text(
                      '앱을 사용하는 것은 이 한계를 인지하고 동의하는 것을 의미해요.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: DT.gray2,
                        height: 1.55,
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

class _LimitItem extends StatelessWidget {
  final String title;
  final String body;
  final bool stress;
  final bool last;

  const _LimitItem({
    required this.title,
    required this.body,
    this.stress = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: DT.text,
                  letterSpacing: -0.29,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: stress ? DT.text : DT.gray,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Divider(
            height: 1,
            thickness: 0.5,
            color: DT.text.withValues(alpha: 0.06),
          ),
      ],
    );
  }
}
