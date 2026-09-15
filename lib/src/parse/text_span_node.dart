import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';

(TextSpanNode?, SpanDecoration) parseTextSpanNode(
  SourceCursor cursor,
  SpanDecoration incoming,
) {
  var style = incoming;
  if (cursor.peek == clusterChar &&
      DecorationAction.chars.contains(cursor.peekAt(1))) {
    style = parseCluster(cursor, style);
  }
  final decorated = style != const SpanDecoration();

  final text = StringBuffer();
  while (true) {
    text.write(cursor.read(textMarkup));

    final char = cursor.peek;
    final next = cursor.peekAt(1);
    if (char.isEmpty || boundaryChars.contains(char)) break;
    if (char == clusterChar && DecorationAction.chars.contains(next)) break;
    if (char == '\n' && decorated) break;
    if (char == '\n' && (next.isEmpty || boundaryChars.contains(next))) break;

    text.write(cursor.take());
  }

  final nextStyle = cursor.peek == '\n' ? const SpanDecoration() : style;
  if (text.isEmpty) return (null, nextStyle);
  return (TextSpanNode(text: text.toString(), decoration: style), nextStyle);
}
