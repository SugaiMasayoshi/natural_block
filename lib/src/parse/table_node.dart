import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_row_node.dart';

TableNode? parseTableNode(SourceCursor cursor) {
  cursor.take();

  final rows = <TableRowNode>[];

  while (!cursor.isEnd && cursor.peek != tableChar) {
    final before = cursor.position;
    // A line break between rows, a blank line included, makes nothing.
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
  if (cursor.peek == tableChar) cursor.take();

  if (rows.every(_isBlank)) return null;
  return TableNode(children: rows);
}

bool _isBlank(TableRowNode row) =>
    row.children.length == 1 && row.children.single.children.isEmpty;
