import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'flat_content_node.dart';
import 'table_node.dart';

/// [atLineStart] is whether the cursor starts a line or a cell, the only
/// place a `~` opens a table or a fence a raw block.
ContentNode? parseContentNode(
  SourceCursor cursor,
  TextPlace place, {
  required bool atLineStart,
}) {
  if (atLineStart && cursor.peek == tableChar) return parseTableNode(cursor);
  return parseFlatContentNode(cursor, place, atLineStart: atLineStart);
}
