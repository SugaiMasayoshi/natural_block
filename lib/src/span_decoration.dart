import 'tone.dart';

class SpanDecoration {
  final int sizeOffset;
  final Tone tone;
  final bool isEmphasized;
  final bool isCustom;

  const SpanDecoration({
    this.sizeOffset = 0,
    this.tone = Tone.none,
    this.isEmphasized = false,
    this.isCustom = false,
  });

  @override
  String toString() =>
      'SpanDecoration(sizeOffset: $sizeOffset, tone: $tone, '
      'isEmphasized: $isEmphasized, isCustom: $isCustom)';

  @override
  bool operator ==(Object other) =>
      other is SpanDecoration &&
      sizeOffset == other.sizeOffset &&
      tone == other.tone &&
      isEmphasized == other.isEmphasized &&
      isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(sizeOffset, tone, isEmphasized, isCustom);
}
