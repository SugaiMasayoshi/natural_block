import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_row_node.dart';

TableNode? parseTableNode(SourceCursor cursor) {
  final start = cursor.position;
  cursor.take();

  final rows = <TableRowNode>[];

  // Every row ends at the start of a line, so only the first can start
  // elsewhere: on the line of the opening `~`.
  var atLineStart = false;
  bool closesTable() => atLineStart && cursor.peek == tableChar;

  while (!cursor.isEnd && !closesTable()) {
    final before = cursor.position;
    if (cursor.peek == '\n') {
      cursor.take();
    } else {
      final escapedClose =
          atLineStart &&
          cursor.peek == escapeChar &&
          cursor.peekAt(1) == tableChar;
      if (escapedClose) cursor.take();
      rows.add(parseTableRowNode(cursor));
    }
    atLineStart = true;
    assert(
      cursor.position > before,
      'table row parse made no progress at ${cursor.position}',
    );
  }
  if (cursor.peek == tableChar) cursor.take();

  if (rows.isEmpty) return null;
  return TableNode(children: rows, start: start, end: cursor.position);
}
