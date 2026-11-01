import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_cell_node.dart';

TableRowNode parseTableRowNode(SourceCursor cursor) {
  final cells = [parseTableCellNode(cursor)];
  while (cursor.peek == rowChar) {
    cursor.take();
    cells.add(parseTableCellNode(cursor));
  }
  return TableRowNode(children: cells);
}
