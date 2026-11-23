import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'layout_node.dart';
import 'raw.dart';
import 'text_node.dart';

/// [atLineStart] is whether the cursor starts a line or a cell, the only
/// place a raw block opens and a `\` keeps the markup after it as text.
FlatContentNode? parseFlatContentNode(
  SourceCursor cursor,
  TextPlace place, {
  required bool atLineStart,
}) {
  if (atLineStart) {
    if (rawBlockAt(cursor.source, cursor.position)) return parseRawNode(cursor);
    final escapedMarker =
        cursor.peek == escapeChar &&
        (layoutOpensAt(cursor.source, cursor.position + 1, place) ||
            cursor.peekAt(1) == tableChar);
    if (escapedMarker) cursor.take();
  }
  return parseTextNode(cursor, place);
}
