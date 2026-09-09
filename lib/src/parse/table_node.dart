import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'separator.dart';
import 'table_row_node.dart';

/// Reads the table that opens at the cursor, both `~` included.
///
/// A `~` wraps rather than separates, and what wraps belongs to what it
/// wraps -- exactly as a verbatim region owns both of its fences. It has to:
/// a table is sized to its own content, so it must know where it stops.
///
/// Null when no row had any content.
TableNode? parseTableNode(SourceCursor cursor) {
  // Its own opening `~`, and the markers on it, which describe the table
  // itself rather than its first row.
  cursor.take();
  final align = takeMarkers(cursor);

  final rows = <TableRowNode>[];

  while (!cursor.isEnd && cursor.peek != tableSymbol) {
    final before = cursor.position;
    final row = parseTableRowNode(cursor);
    if (row != null) rows.add(row);
    assert(
      cursor.position > before,
      'table row parse made no progress at ${cursor.position}',
    );
  }
  if (cursor.peek == tableSymbol) cursor.take();

  // And the newline written after it, which belongs to the boundary; see the
  // rule in `parse/document.dart`.
  if (cursor.peek == '\n') cursor.take();

  if (rows.isEmpty) return null;
  return TableNode(align: align, children: rows);
}
