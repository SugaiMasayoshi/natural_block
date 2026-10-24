import '../markup.dart';
import '../span_decoration.dart';
import '../tone.dart';

extension SpanDecorationActions on SpanDecoration {
  SpanDecoration apply(DecorationAction action) => switch (action) {
    DecorationAction.larger => _copy(sizeOffset: sizeOffset + 1),
    DecorationAction.smaller => _copy(sizeOffset: sizeOffset - 1),
    DecorationAction.negative => _copy(tone: _toggle(Tone.negative)),
    DecorationAction.positive => _copy(tone: _toggle(Tone.positive)),
    DecorationAction.emphasis => _copy(isEmphasized: !isEmphasized),
    DecorationAction.custom => _copy(isCustom: !isCustom),
    DecorationAction.reset => _copy(
      tone: Tone.none,
      isEmphasized: false,
      isCustom: false,
    ),
  };

  Tone _toggle(Tone next) => tone == next ? Tone.none : next;

  SpanDecoration _copy({
    int? sizeOffset,
    Tone? tone,
    bool? isEmphasized,
    bool? isCustom,
  }) => SpanDecoration(
    sizeOffset: sizeOffset ?? this.sizeOffset,
    tone: tone ?? this.tone,
    isEmphasized: isEmphasized ?? this.isEmphasized,
    isCustom: isCustom ?? this.isCustom,
  );
}
