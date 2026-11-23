import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_row_node.dart';

/// Whether a `~` stands alone on the line starting at [position], which
/// opens a table or closes the one it is in.
bool tableAt(String source, int position) =>
    position < source.length &&
    source[position] == tableChar &&
    (position + 1 == source.length || source[position + 1] == '\n');

TableNode? parseTableNode(SourceCursor cursor) {
  final start = cursor.position;
  cursor.take();
  if (cursor.peek == '\n') cursor.take();

  final rows = <TableRowNode>[];
  while (!cursor.isEnd && !tableAt(cursor.source, cursor.position)) {
    final before = cursor.position;
    if (cursor.peek == '\n') {
      cursor.take();
    } else {
      rows.add(parseTableRowNode(cursor));
    }
    assert(
      cursor.position > before,
      'table row parse made no progress at ${cursor.position}',
    );
  }
  if (!cursor.isEnd) cursor.take();

  if (rows.isEmpty) return null;
  return TableNode(children: rows, start: start, end: cursor.position);
}
