// 【解説】[読む順 20/23] インラインの振り分け。
// 【解説】
// 【解説】 行頭でないフェンスなら文中のraw 区間、それ以外は文字の run。
// 【解説】 装飾の状態を受け取り、次に渡す状態と一緒に返す。
// 【解説】 次: src/parse/text_span_node.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'raw.dart';
import 'text_span_node.dart';

(InlineNode?, SpanDecoration) parseInlineNode(
  SourceCursor cursor,
  SpanDecoration style,
) {
  if (cursor.peek == rawChar && !cursor.atLineStart) {
    return (parseRawSpanNode(cursor), style);
  }
  return parseTextSpanNode(cursor, style);
}
