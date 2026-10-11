import 'tone.dart';

class SpanDecoration {
  final int sizeOffset;
  final Tone tone;
  final bool emphasis;
  final bool isCustom;

  const SpanDecoration({
    this.sizeOffset = 0,
    this.tone = Tone.none,
    this.emphasis = false,
    this.isCustom = false,
  });

  @override
  String toString() =>
      'SpanDecoration(sizeOffset: $sizeOffset, tone: $tone, '
      'emphasis: $emphasis, isCustom: $isCustom)';

  @override
  bool operator ==(Object other) =>
      other is SpanDecoration &&
      sizeOffset == other.sizeOffset &&
      tone == other.tone &&
      emphasis == other.emphasis &&
      isCustom == other.isCustom;

  @override
  int get hashCode => Object.hash(sizeOffset, tone, emphasis, isCustom);
}
