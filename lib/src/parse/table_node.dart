import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_row_node.dart';

TableNode? parseTableNode(SourceCursor cursor) {
  cursor.take();

  final rows = <TableRowNode>[];

  while (!cursor.isEnd && cursor.peek != tableChar) {
    final before = cursor.position;
    if (cursor.peek == columnChar) cursor.take();
    final row = parseTableRowNode(cursor);
    if (row != null) rows.add(row);
    assert(
      cursor.position > before,
      'table row parse made no progress at ${cursor.position}',
    );
  }
  if (cursor.peek == tableChar) cursor.take();

  if (rows.isEmpty) return null;
  return TableNode(children: rows);
}
