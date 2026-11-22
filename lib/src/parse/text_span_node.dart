import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';

(TextSpanNode?, SpanDecoration) parseTextSpanNode(
  SourceCursor cursor,
  SpanDecoration incoming,
  TextPlace place,
) {
  final start = cursor.position;
  var style = incoming;
  if (_clusterAt(cursor)) style = parseCluster(cursor, style);
  final markup = {...place.boundaries, clusterChar};

  final text = StringBuffer();
  while (true) {
    text.write(cursor.read(markup));
    final plainColon =
        cursor.peek == clusterChar &&
        !DecorationAction.chars.contains(cursor.peekAt(1));
    if (!plainColon) break;
    text.write(cursor.take());
  }

  final content = text.toString();
  if (content.isEmpty) return (null, style);
  final span = TextSpanNode(
    text: content,
    decoration: style,
    start: start,
    end: cursor.position,
  );
  return (span, style);
}

bool _clusterAt(SourceCursor cursor) =>
    cursor.peek == clusterChar &&
    DecorationAction.chars.contains(cursor.peekAt(1));
