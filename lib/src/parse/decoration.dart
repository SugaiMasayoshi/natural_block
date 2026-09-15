// 【解説】[読む順 22/23] 装飾クラスタ(:+!* など)を読み、新しい装飾を返す。
// 【解説】
// 【解説】 開きの : から食べ、装飾の文字でないものが来たら終わる。\ でも終わる。
// 【解説】 次が + - ! % * @(文中では記号でない文字)なら \ だけを食べ、その文字は
// 【解説】 本文に残す。\| や \: などは、run が自分でエスケープとして読む。
// 【解説】 11番の寄せと同じ形。
// 【解説】 次: src/parse/span_decoration.dart
import '../markup.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'span_decoration.dart';

SpanDecoration parseCluster(SourceCursor cursor, SpanDecoration style) {
  cursor.take();

  var result = style;
  while (!cursor.isEnd) {
    final char = cursor.peek;

    if (char == escapeChar) {
      final next = cursor.peekAt(1);
      if (DecorationAction.chars.contains(next) && !textMarkup.contains(next)) {
        cursor.take();
      }
      return result;
    }

    final action = DecorationAction.byChar[char];
    if (action == null) return result;
    cursor.take();
    result = result.apply(action);
  }
  return result;
}
