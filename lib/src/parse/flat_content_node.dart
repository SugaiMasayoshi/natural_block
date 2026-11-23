import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'raw.dart';
import 'text_node.dart';

/// [atLineStart] is whether the cursor starts a line or a cell, the only
/// place a raw block opens.
FlatContentNode? parseFlatContentNode(
  SourceCursor cursor,
  TextPlace place, {
  required bool atLineStart,
}) {
  if (atLineStart && rawBlockAt(cursor.source, cursor.position)) {
    return parseRawNode(cursor);
  }
  return parseTextNode(cursor, place);
}
