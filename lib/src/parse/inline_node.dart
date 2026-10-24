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
  if (cursor.peek == rawChar) {
    // A block ends the text it interrupts; the column reads it next.
    if (rawBlockAt(cursor.source, cursor.position)) return (null, style);
    return (parseRawSpanNode(cursor), style);
  }
  return parseTextSpanNode(cursor, style);
}
