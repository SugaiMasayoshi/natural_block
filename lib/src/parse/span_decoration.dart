// 【解説】[読む順 23/23] 装飾の文字1つを SpanDecoration に適用する。
// 【解説】
// 【解説】 + と - はサイズを1段ずつ。トーン・強調・アクションはトグル(もう一度で消える)。
// 【解説】 :: はトーン・強調・アクションを戻すが、サイズは戻さない。
// 【解説】 このファイルは export されないので、apply も _copy / _toggle も外から見えない。
// 【解説】 これで全部。
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
