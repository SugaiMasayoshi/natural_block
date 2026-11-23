import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'flat_content_node.dart';
import 'table_node.dart';

/// [atLineStart] is whether the cursor starts a line or a cell, the only
/// place a `~` alone on its line opens a table or a fence a raw block.
ContentNode? parseContentNode(
  SourceCursor cursor,
  TextPlace place, {
  required bool atLineStart,
}) {
  if (atLineStart && tableAt(cursor.source, cursor.position)) {
    return parseTableNode(cursor);
  }
  return parseFlatContentNode(cursor, place, atLineStart: atLineStart);
}
