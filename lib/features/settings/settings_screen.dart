import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/design_tokens.dart';
import '../diagnosis/diagnosis_screen.dart';

const _kPrivacyPolicyUrl = 'https://yulgoklee.github.io/mask/';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = '${info.version} (${info.buildNumber})';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.background,
      appBar: AppBar(
        backgroundColor: DT.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DT.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: DT.text,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _SettingsSection(
            label: '알림',
            children: [
              _SettingsRow(
                title: '알림 설정',
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            label: '진단',
            children: [
              _SettingsRow(
                title: '재진단 받기',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DiagnosisScreen(),
                    fullscreenDialog: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            label: '앱 정보',
            children: [
              _SettingsRow(
                title: '버전 정보',
                trailing: Text(
                  _version ?? '',
                  style: const TextStyle(fontSize: 13, color: DT.gray),
                ),
              ),
              const _Divider(),
              _SettingsRow(
                title: '개인정보처리방침',
                onTap: () => launchUrl(
                  Uri.parse(_kPrivacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const _Divider(),
              _SettingsRow(
                title: '오픈소스 라이선스',
                onTap: () => showLicensePage(context: context),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── 섹션 컨테이너 ─────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _SettingsSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DT.gray,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: DT.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DT.border),
            boxShadow: const [
              BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x0F000000)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── 행 아이템 ─────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({required this.title, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: DT.text,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null) ...[
              if (trailing != null) const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20, color: DT.gray),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 구분선 ────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: DT.border,
    );
  }
}
