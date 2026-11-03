import 'tone.dart';

/// What the source said about a run of text.
class SpanDecoration {
  /// Size steps: one per `:+`, minus one per `:-`.
  final int sizeOffset;

  final Tone tone;

  /// `:*`
  final bool isEmphasized;

  /// Between `:@` marks. The run's text is the payload; what it means is the
  /// app's to decide.
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
