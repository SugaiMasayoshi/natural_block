import 'tone.dart';

class SpanDecoration {
  final int sizeOffset;
  final Tone tone;
  final bool emphasis;
  final bool isAction;

  const SpanDecoration({
    this.sizeOffset = 0,
    this.tone = Tone.none,
    this.emphasis = false,
    this.isAction = false,
  });

  @override
  String toString() =>
      'SpanDecoration(sizeOffset: $sizeOffset, tone: $tone, '
      'emphasis: $emphasis, isAction: $isAction)';

  @override
  bool operator ==(Object other) =>
      other is SpanDecoration &&
      sizeOffset == other.sizeOffset &&
      tone == other.tone &&
      emphasis == other.emphasis &&
      isAction == other.isAction;

  @override
  int get hashCode => Object.hash(sizeOffset, tone, emphasis, isAction);
}
