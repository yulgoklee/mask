enum QuickStateType { cold, skinTreatment, outdoorActive }

class QuickState {
  final bool isCold;
  final bool hasSkinTreatment;
  final bool isOutdoorActive;
  final DateTime? lastResetDate;

  const QuickState({
    this.isCold = false,
    this.hasSkinTreatment = false,
    this.isOutdoorActive = false,
    this.lastResetDate,
  });

  factory QuickState.initial() => const QuickState();

  bool isOn(QuickStateType type) => switch (type) {
    QuickStateType.cold          => isCold,
    QuickStateType.skinTreatment => hasSkinTreatment,
    QuickStateType.outdoorActive => isOutdoorActive,
  };

  QuickState toggle(QuickStateType type) => switch (type) {
    QuickStateType.cold          => copyWith(isCold: !isCold),
    QuickStateType.skinTreatment => copyWith(hasSkinTreatment: !hasSkinTreatment),
    QuickStateType.outdoorActive => copyWith(isOutdoorActive: !isOutdoorActive),
  };

  QuickState copyWith({
    bool? isCold,
    bool? hasSkinTreatment,
    bool? isOutdoorActive,
    DateTime? lastResetDate,
  }) =>
      QuickState(
        isCold: isCold ?? this.isCold,
        hasSkinTreatment: hasSkinTreatment ?? this.hasSkinTreatment,
        isOutdoorActive: isOutdoorActive ?? this.isOutdoorActive,
        lastResetDate: lastResetDate ?? this.lastResetDate,
      );

  QuickState resetDaily() => copyWith(
    isCold: false,
    isOutdoorActive: false,
    lastResetDate: DateTime.now(),
  );
}
