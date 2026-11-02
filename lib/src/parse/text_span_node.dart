import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';
import 'raw.dart';

(TextSpanNode?, SpanDecoration) parseTextSpanNode(
  SourceCursor cursor,
  SpanDecoration incoming,
  TextPlace place,
) {
  var style = incoming;
  if (cursor.peek == clusterChar &&
      DecorationAction.chars.contains(cursor.peekAt(1))) {
    style = parseCluster(cursor, style);
  }
  final decorated = style != const SpanDecoration();
  final markup = {...place.boundaries, clusterChar};

  final text = StringBuffer();
  while (true) {
    text.write(cursor.read(markup));

    final char = cursor.peek;
    if (char.isEmpty || place.boundaries.contains(char)) break;
    if (char == clusterChar &&
        DecorationAction.chars.contains(cursor.peekAt(1))) {
      break;
    }
    if (char == '\n' && _endsText(cursor, place)) break;

    text.write(cursor.take());
    if (char != '\n') continue;

    // A marker escaped at the start of a line is text.
    if (place == TextPlace.block &&
        cursor.peek == escapeChar &&
        opensBlock(cursor.peekAt(1))) {
      cursor.take();
    }
    if (decorated) break;
  }

  final content = text.toString();
  final nextStyle = content.endsWith('\n') ? const SpanDecoration() : style;
  if (content.isEmpty) return (null, nextStyle);
  return (TextSpanNode(text: content, decoration: style), nextStyle);
}

/// Whether the newline at the cursor ends the text rather than being part of
/// it: the next line belongs to something else.
bool _endsText(SourceCursor cursor, TextPlace place) {
  if (place == TextPlace.tableCell) return true;
  final next = cursor.peekAt(1);
  if (place == TextPlace.block && opensBlock(next)) return true;
  if (next == rawChar) return rawBlockAt(cursor.source, cursor.position + 1);
  return place.boundaries.contains(next);
}
