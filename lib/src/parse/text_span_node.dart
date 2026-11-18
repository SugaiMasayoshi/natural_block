import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'decoration.dart';
import 'line_start.dart';
import 'raw.dart';

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

    if (cursor.isEnd || place.boundaries.contains(cursor.peek)) break;
    if (cursor.peek == clusterChar) {
      if (_clusterAt(cursor)) break;
      text.write(cursor.take());
      continue;
    }

    // At a newline, which ends the decoration and is never decorated itself.
    if (_endsText(cursor, place)) break;
    if (style != const SpanDecoration()) {
      if (text.isNotEmpty) break;
      style = const SpanDecoration();
    }
    text.write(cursor.take());
    final next = cursor.peekAt(1);
    final escapedMarker =
        cursor.peek == escapeChar &&
        (next == tableChar ||
            opensLine(cursor.source, cursor.position + 1, place));
    if (escapedMarker) cursor.take();
  }

  final content = text.toString();
  final nextStyle = cursor.peek == '\n' ? const SpanDecoration() : style;
  if (content.isEmpty) return (null, nextStyle);
  final span = TextSpanNode(
    text: content,
    decoration: style,
    start: start,
    end: cursor.position,
  );
  return (span, nextStyle);
}

bool _clusterAt(SourceCursor cursor) =>
    cursor.peek == clusterChar &&
    DecorationAction.chars.contains(cursor.peekAt(1));

/// Whether the newline at the cursor ends the text rather than being part of
/// it: the next line belongs to something else.
bool _endsText(SourceCursor cursor, TextPlace place) {
  final next = cursor.peekAt(1);
  if (next == tableChar) return true;
  if (opensLine(cursor.source, cursor.position + 1, place)) return true;
  if (next == rawChar) return rawBlockAt(cursor.source, cursor.position + 1);
  return place.boundaries.contains(next);
}
