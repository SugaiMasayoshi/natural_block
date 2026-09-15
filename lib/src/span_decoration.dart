// 【解説】[読む順 4/23] 1つの run の装飾(サイズ・トーン・強調・アクション)をまとめた値。
// 【解説】
// 【解説】 パーサが読みながら持ち歩く「今の装飾」と、木の TextSpanNode に載る
// 【解説】 装飾は同じこの型。4つの軸は互いに独立で、どれも他を戻さない。
// 【解説】 公開するのは値と比較だけ。変更(apply)は 23番の非公開の拡張にある。
// 【解説】 次: src/nodes.dart
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
