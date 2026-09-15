// 【解説】[読む順 21/23] 文字の run。装飾・改行・記号がすべてここで出会う。
// 【解説】
// 【解説】 1. 始まりのクラスタ(:!* など)を先に適用し、この run の装飾を決める。
// 【解説】 2. read(textMarkup) で記号の手前まで読み、_endsRun で本当に終わるかを
// 【解説】    判定する。終わらないもの(記号にならない : や、途中の改行)は1文字
// 【解説】    取って続ける。
// 【解説】 3. 改行: 装飾があれば run を終える(装飾は改行でリセット)。境界に接した
// 【解説】    改行(_touchesBoundary)なら手前で止まり、列(10番)かセル(16番)のループに任せる。
// 【解説】 戻り値は run と、次の run に渡す装飾。
// 【解説】 次: src/parse/decoration.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';

bool _opensCluster(SourceCursor cursor) =>
    cursor.peek == clusterChar &&
    DecorationAction.byChar.containsKey(cursor.peekAt(1));

bool _touchesBoundary(SourceCursor cursor) {
  final next = cursor.peekAt(1);
  return next.isEmpty ||
      layoutChars.contains(next) ||
      contentChars.contains(next);
}

bool _endsRun(SourceCursor cursor, SpanDecoration style) =>
    switch (cursor.peek) {
      '\n' => style != const SpanDecoration() || _touchesBoundary(cursor),

      clusterChar => _opensCluster(cursor),
      _ => true,
    };

(TextSpanNode?, SpanDecoration) parseTextSpanNode(
  SourceCursor cursor,
  SpanDecoration incoming,
) {
  final pending = StringBuffer();
  var style = incoming;

  while (_opensCluster(cursor)) {
    style = parseCluster(cursor, style);
  }

  while (true) {
    pending.write(cursor.read(textMarkup));
    if (cursor.isEnd || _endsRun(cursor, style)) break;
    pending.write(cursor.take());
  }

  final outgoing = cursor.peek == '\n' ? const SpanDecoration() : style;

  final run = pending.toString();

  return (
    run.isEmpty ? null : TextSpanNode(text: run, decoration: style),
    outgoing,
  );
}
