import 'package:flutter/material.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/location_stations.dart';
import '../diagnosis_cards_helpers.dart';

// ══════════════════════════════════════════════════════════════
//  QLocation — 관심 지역 (집 / 회사·학교)
//  에어코리아 API 검증 측정소명을 시도 + 구/군 2단계 드롭다운으로 선택
//  iOS 백그라운드 알림 Fallback + 가장 가까운 측정소 자동 매핑용
// ══════════════════════════════════════════════════════════════

class DiagQLocation extends StatefulWidget {
  final String homeStation;
  final String officeStation;
  final ValueChanged<String> onHomeChanged;
  final ValueChanged<String> onOfficeChanged;
  final int questionNumber;

  const DiagQLocation({
    super.key,
    required this.homeStation,
    required this.officeStation,
    required this.onHomeChanged,
    required this.onOfficeChanged,
    this.questionNumber = 2,
  });

  @override
  State<DiagQLocation> createState() => _DiagQLocationState();
}

class _DiagQLocationState extends State<DiagQLocation> {
  // 집
  String? _homeSido;
  String? _homeDistrict;

  // 회사
  String? _officeSido;
  String? _officeDistrict;

  List<String> _districtsFor(String? sido) {
    if (sido == null) return [];
    return locationRegionStations[sido]?.keys.toList() ?? [];
  }

  String? _stationFor(String? sido, String? district) {
    if (sido == null || district == null) return null;
    return locationRegionStations[sido]?[district];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          qBadge('Q${widget.questionNumber} · 위치 설정'),
          const SizedBox(height: 14),
          qTitle(context, '자주 계시는 곳을\n알려주세요'),
          const SizedBox(height: 8),
          qSubtitle(
            context,
            '앱이 백그라운드 상태일 때 이 지역의 측정소 데이터로 알림을 보내요.',
          ),
          const SizedBox(height: 36),
          _locationPicker(
            label: '🏠  집',
            sido: _homeSido,
            district: _homeDistrict,
            onSidoChanged: (v) => setState(() {
              _homeSido = v;
              _homeDistrict = null;
              widget.onHomeChanged('');
            }),
            onDistrictChanged: (v) {
              setState(() => _homeDistrict = v);
              final station = _stationFor(_homeSido, v);
              if (station != null) widget.onHomeChanged(station);
            },
          ),
          const SizedBox(height: 24),
          _locationPicker(
            label: '🏢  회사 · 학교',
            sido: _officeSido,
            district: _officeDistrict,
            onSidoChanged: (v) => setState(() {
              _officeSido = v;
              _officeDistrict = null;
              widget.onOfficeChanged('');
            }),
            onDistrictChanged: (v) {
              setState(() => _officeDistrict = v);
              final station = _stationFor(_officeSido, v);
              if (station != null) widget.onOfficeChanged(station);
            },
          ),
          const SizedBox(height: 28),
          insightBox(
            '선택하지 않아도 앱은 정상 동작해요. '
            '나중에 프로필 탭에서 언제든지 수정할 수 있어요.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _locationPicker({
    required String label,
    required String? sido,
    required String? district,
    required ValueChanged<String?> onSidoChanged,
    required ValueChanged<String?> onDistrictChanged,
  }) {
    final districts = _districtsFor(sido);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DT.text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 시도
            Expanded(
              flex: 2,
              child: _dropdownField(
                hint: '시/도',
                value: sido,
                items: locationSidoList,
                onChanged: onSidoChanged,
              ),
            ),
            const SizedBox(width: 10),
            // 구/군 (시도 선택 전 비활성)
            Expanded(
              flex: 3,
              child: _dropdownField(
                hint: '구/군 선택',
                value: district,
                items: districts,
                onChanged: sido == null ? null : onDistrictChanged,
              ),
            ),
          ],
        ),
        if (district != null && sido != null) ...[
          const SizedBox(height: 6),
          Text(
            '측정소: ${_stationFor(sido, district) ?? '-'}',
            style: const TextStyle(
              fontSize: 11,
              color: DT.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: onChanged == null
            ? DT.border
            : DT.grayLt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null ? DT.primary : DT.border,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: DT.gray,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            fontSize: 13,
            color: DT.text,
          ),
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}
