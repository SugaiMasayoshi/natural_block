import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_cell_node.dart';

/// A row from its opening `^`, which a line may leave out, to the `^` that
/// ends a line, or to the end of the table or the document.
TableRowNode parseTableRowNode(SourceCursor cursor) {
  if (cursor.peek == rowChar) cursor.take();

  final cells = <TableCellNode>[];
  while (true) {
    cells.add(parseTableCellNode(cursor));
    if (cursor.peek != rowChar) break;

    cursor.take();
    if (cursor.isEnd || cursor.peek == tableChar) break;
    if (cursor.peek == '\n') {
      cursor.take();
      break;
    }
  }
  return TableRowNode(children: cells);
}
