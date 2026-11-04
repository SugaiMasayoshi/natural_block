import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'flat_content_node.dart';
import 'table_node.dart';

/// [atLineStart] is whether the cursor starts a line or a cell, the only
/// place a `~` opens a table.
ContentNode? parseContentNode(
  SourceCursor cursor,
  TextPlace place, {
  required bool atLineStart,
}) {
  if (atLineStart) {
    if (cursor.peek == tableChar) return parseTableNode(cursor);
    if (cursor.peek == escapeChar && cursor.peekAt(1) == tableChar) {
      cursor.take();
    }
  }
  return parseFlatContentNode(cursor, place);
}
