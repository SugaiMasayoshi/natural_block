import '../markup.dart';
import '../span_decoration.dart';
import '../tone.dart';

extension SpanDecorationActions on SpanDecoration {
  SpanDecoration apply(DecorationAction action) => switch (action) {
    DecorationAction.larger => _copy(sizeOffset: sizeOffset + 1),
    DecorationAction.smaller => _copy(sizeOffset: sizeOffset - 1),
    DecorationAction.negative => _copy(tone: _toggle(Tone.negative)),
    DecorationAction.positive => _copy(tone: _toggle(Tone.positive)),
    DecorationAction.emphasis => _copy(emphasis: !emphasis),
    DecorationAction.action => _copy(isAction: !isAction),
    DecorationAction.reset => _copy(
      tone: Tone.none,
      emphasis: false,
      isAction: false,
    ),
  };

  Tone _toggle(Tone next) => tone == next ? Tone.none : next;

  SpanDecoration _copy({
    int? sizeOffset,
    Tone? tone,
    bool? emphasis,
    bool? isAction,
  }) => SpanDecoration(
    sizeOffset: sizeOffset ?? this.sizeOffset,
    tone: tone ?? this.tone,
    emphasis: emphasis ?? this.emphasis,
    isAction: isAction ?? this.isAction,
  );
}
