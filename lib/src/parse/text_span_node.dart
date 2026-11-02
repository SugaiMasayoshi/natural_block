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
  if (_clusterAt(cursor)) style = parseCluster(cursor, style);
  final decorated = style != const SpanDecoration();
  final markup = {...place.boundaries, clusterChar};

  final text = StringBuffer();
  while (true) {
    text.write(cursor.read(markup));

    if (cursor.isEnd || place.boundaries.contains(cursor.peek)) break;
    if (cursor.peek == clusterChar) {
      if (_clusterAt(cursor)) break;
      text.write(cursor.take());
      continue;
    }

    // At a newline.
    if (_endsText(cursor, place)) break;
    text.write(cursor.take());
    if (place == TextPlace.block) _skipEscapeAtLineStart(cursor);
    if (decorated) break;
  }

  final content = text.toString();
  final nextStyle = content.endsWith('\n') ? const SpanDecoration() : style;
  if (content.isEmpty) return (null, nextStyle);
  return (TextSpanNode(text: content, decoration: style), nextStyle);
}

bool _clusterAt(SourceCursor cursor) =>
    cursor.peek == clusterChar &&
    DecorationAction.chars.contains(cursor.peekAt(1));

/// Drops the backslash before a marker at the start of a line, so the marker
/// is text.
void _skipEscapeAtLineStart(SourceCursor cursor) {
  if (cursor.peek == escapeChar && opensBlock(cursor.peekAt(1))) cursor.take();
}

/// Whether the newline at the cursor ends the text rather than being part of
/// it: the next line belongs to something else.
bool _endsText(SourceCursor cursor, TextPlace place) {
  final next = cursor.peekAt(1);
  if (place == TextPlace.block && opensBlock(next)) return true;
  if (next == rawChar) return rawBlockAt(cursor.source, cursor.position + 1);
  return place.boundaries.contains(next);
}
