import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'raw.dart';
import 'text_span_node.dart';

(InlineNode?, SpanDecoration) parseInlineNode(
  SourceCursor cursor,
  SpanDecoration style,
  TextPlace place,
) {
  if (cursor.peek == rawChar) return (parseRawSpanNode(cursor, style), style);
  return parseTextSpanNode(cursor, style, place);
}
