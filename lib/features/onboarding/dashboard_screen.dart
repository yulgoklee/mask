import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_profile.dart';

/// Phase 3: 데이터 분석 대시보드
///
/// 1.5초 분석 로딩 → 페르소나 매칭 → T_final 공개 → Area Chart
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  late final AnimationController _contentCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // 콘텐츠 페이드인 컨트롤러
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    // 1.5초 로딩 후 대시보드 노출
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _contentCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // arguments로 전달된 UserProfile
    final profile =
        ModalRoute.of(context)?.settings.arguments as UserProfile? ??
            UserProfile.defaultProfile();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? _LoadingView()
            : FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _DashboardContent(profile: profile),
                ),
              ),
      ),
    );
  }
}

// ── 1.5초 로딩 뷰 ───────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotCtrl;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _dotCount = (_dotCount + 1) % 4);
          _dotCtrl.reset();
          _dotCtrl.forward();
        }
      });
    _dotCtrl.forward();
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: AppColors.splashBackground,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '데이터를 분석 중입니다$dots',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '나만의 안전 기준선을 계산하고 있어요',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 대시보드 콘텐츠 ──────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final UserProfile profile;

  const _DashboardContent({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          _buildHeader(),
          const SizedBox(height: 28),

          // 페르소나 매칭 카드
          _PersonaCard(profile: profile),
          const SizedBox(height: 16),

          // T_final 수치 카드
          _TFinalCard(profile: profile),
          const SizedBox(height: 16),

          // 마스크 효과 Area Chart 카드
          _MaskEffectCard(profile: profile),
          const SizedBox(height: 32),

          // 다음 단계 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(
                '/notification_custom',
                arguments: profile,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.splashBackground,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                '알림 스타일 설정하기 →',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 스테퍼 (2단계 활성)
        const _MiniStepper(activeStep: 1),
        const SizedBox(height: 20),
        const Text(
          '분석 완료! 🎉',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${profile.displayName}\n맞춤 기준선이 만들어졌어요.',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.35,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

// ── 페르소나 매칭 카드 ────────────────────────────────────────

class _PersonaCard extends StatelessWidget {
  final UserProfile profile;
  const _PersonaCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.splashBackground.withOpacity(0.15),
            AppColors.splashBackground.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.splashBackground.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.splashBackground.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🛡️', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '당신의 가디언 타입',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.personaLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── T_final 수치 카드 ─────────────────────────────────────────

class _TFinalCard extends StatefulWidget {
  final UserProfile profile;
  const _TFinalCard({required this.profile});

  @override
  State<_TFinalCard> createState() => _TFinalCardState();
}

class _TFinalCardState extends State<_TFinalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _numAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _numAnim = Tween<double>(begin: 35.0, end: widget.profile.tFinal)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile.displayName;
    final tFinal = widget.profile.tFinal;
    final savedAmount = 35.0 - tFinal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 레이블
          Row(
            children: [
              const Icon(Icons.science_outlined,
                  size: 18, color: AppColors.splashBackground),
              const SizedBox(width: 6),
              const Text(
                '나만의 PM2.5 안전 기준선',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 수치 카운트업
          AnimatedBuilder(
            animation: _numAnim,
            builder: (_, __) => RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _numAnim.value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.splashBackground,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -2,
                    ),
                  ),
                  const TextSpan(
                    text: ' μg/m³',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 비교 문구
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppColors.textSecondary),
              children: [
                TextSpan(text: '일반 기준(35μg/m³)보다 '),
                TextSpan(
                  text: '${savedAmount.toStringAsFixed(1)}μg/m³ 낮은 ',
                  style: const TextStyle(
                    color: AppColors.warningCoral,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: '$name의 안전 기준이에요.'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 감도 지수 바
          _SensitivityBar(s: widget.profile.sensitivityIndex),
        ],
      ),
    );
  }
}

class _SensitivityBar extends StatelessWidget {
  final double s;
  const _SensitivityBar({required this.s});

  @override
  Widget build(BuildContext context) {
    // s: 0.1 ~ 0.6 → width ratio
    final ratio = (s - 0.1) / 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '민감도 지수',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              's = ${s.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              Color.lerp(
                    AppColors.splashBackground,
                    AppColors.warningCoral,
                    ratio,
                  ) ??
                  AppColors.splashBackground,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 마스크 효과 Area Chart 카드 ──────────────────────────────

class _MaskEffectCard extends StatelessWidget {
  final UserProfile profile;
  const _MaskEffectCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 18, color: AppColors.splashBackground),
              SizedBox(width: 6),
              Text(
                '마스크 착용 효과',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 커스텀 Area Chart (flutter 내장으로 구현)
          _AreaChartPainter(tFinal: profile.tFinal),
          const SizedBox(height: 16),

          // 범례
          Row(
            children: [
              _LegendDot(color: AppColors.warningCoral.withOpacity(0.6)),
              const SizedBox(width: 6),
              const Text(
                '미착용 시 흡입량',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.splashBackground.withOpacity(0.6)),
              const SizedBox(width: 6),
              const Text(
                '착용 후 방어량',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// 커스텀 Area Chart — flutter_chart 의존성 없이 CustomPainter로 구현
class _AreaChartPainter extends StatefulWidget {
  final double tFinal;
  const _AreaChartPainter({required this.tFinal});

  @override
  State<_AreaChartPainter> createState() => _AreaChartPainterState();
}

class _AreaChartPainterState extends State<_AreaChartPainter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 140),
        painter: _ChartPainter(
          tFinal: widget.tFinal,
          progress: _anim.value,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final double tFinal;
  final double progress;

  _ChartPainter({required this.tFinal, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // PM2.5 값 시뮬레이션 포인트 (0~75 범위 정규화)
    const double maxPm = 75.0;
    final List<double> rawValues = [
      10, 18, 25, 32, 45, 58, 65, 70, 62, 50, 38, 25, 15
    ];
    final int n = rawValues.length;

    // 미착용 영역 (Warm Coral)
    final pathUnmasked = Path();
    final paintUnmasked = Paint()
      ..color = AppColors.warningCoral.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final lineUnmasked = Paint()
      ..color = AppColors.warningCoral.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 착용 후 영역 (Sky Blue) — tFinal 이하로 클리핑
    final pathMasked = Path();
    final paintMasked = Paint()
      ..color = AppColors.splashBackground.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final lineMasked = Paint()
      ..color = AppColors.splashBackground.withOpacity(0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // T_final 기준선
    final tY = size.height * (1 - tFinal / maxPm);
    final lineTFinal = Paint()
      ..color = AppColors.splashBackground
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 좌표 계산
    List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final x = size.width * i / (n - 1);
      final y = size.height * (1 - (rawValues[i] / maxPm) * progress);
      points.add(Offset(x, y));
    }

    // 미착용 path
    pathUnmasked.moveTo(0, size.height);
    pathUnmasked.lineTo(points[0].dx, points[0].dy);
    for (int i = 1; i < n; i++) {
      final cp = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        (points[i - 1].dy + points[i].dy) / 2,
      );
      pathUnmasked.quadraticBezierTo(
          points[i - 1].dx, points[i - 1].dy, cp.dx, cp.dy);
    }
    pathUnmasked.lineTo(points.last.dx, points.last.dy);
    pathUnmasked.lineTo(size.width, size.height);
    pathUnmasked.close();

    // 착용 후 path — tFinal 이하 부분만
    final maskedLine = Path();
    pathMasked.moveTo(0, size.height);
    maskedLine.moveTo(points[0].dx, points[0].dy.clamp(tY, size.height));

    pathMasked.lineTo(points[0].dx, points[0].dy.clamp(tY, size.height));
    for (int i = 1; i < n; i++) {
      final cpy = ((points[i - 1].dy + points[i].dy) / 2).clamp(tY, size.height);
      final cpx = (points[i - 1].dx + points[i].dx) / 2;
      pathMasked.quadraticBezierTo(points[i - 1].dx,
          points[i - 1].dy.clamp(tY, size.height), cpx, cpy);
      maskedLine.quadraticBezierTo(points[i - 1].dx,
          points[i - 1].dy.clamp(tY, size.height), cpx, cpy);
    }
    pathMasked.lineTo(size.width, size.height);
    pathMasked.close();

    // 그리기
    canvas.drawPath(pathUnmasked, paintUnmasked);
    canvas.drawPath(pathMasked, paintMasked);

    // 선 그리기
    final unmaskedLine = Path();
    unmaskedLine.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < n; i++) {
      final cp = Offset(
        (points[i - 1].dx + points[i].dx) / 2,
        (points[i - 1].dy + points[i].dy) / 2,
      );
      unmaskedLine.quadraticBezierTo(
          points[i - 1].dx, points[i - 1].dy, cp.dx, cp.dy);
    }
    canvas.drawPath(unmaskedLine, lineUnmasked);
    canvas.drawPath(maskedLine, lineMasked);

    // T_final 기준선 점선
    _drawDashedLine(
        canvas, Offset(0, tY), Offset(size.width, tY), lineTFinal);

    // T_final 레이블
    final textPainter = TextPainter(
      text: TextSpan(
        text: ' ${tFinal.toStringAsFixed(0)}μg/m³',
        style: const TextStyle(
          color: AppColors.splashBackground,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(4, tY - 14));
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double distance = 0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = (end - start).distance;
    while (distance < length) {
      final ratio = distance / length;
      final x0 = start.dx + dx * ratio;
      final y0 = start.dy + dy * ratio;
      final ratio2 = (distance + dashWidth).clamp(0.0, length) / length;
      final x1 = start.dx + dx * ratio2;
      final y1 = start.dy + dy * ratio2;
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.tFinal != tFinal || old.progress != progress;
}

// ── 미니 스테퍼 (대시보드 상단용) ────────────────────────────

class _MiniStepper extends StatelessWidget {
  final int activeStep;
  const _MiniStepper({required this.activeStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['진단', '분석', '세팅'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 1.5,
              color: i ~/ 2 < activeStep
                  ? AppColors.splashBackground
                  : AppColors.divider,
            ),
          );
        }
        final idx = i ~/ 2;
        final isActive = idx == activeStep;
        final isDone = idx < activeStep;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive || isDone
                ? AppColors.splashBackground
                : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
