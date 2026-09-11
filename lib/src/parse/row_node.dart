import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';

RowNode parseRowNode(SourceCursor cursor, ColumnNode first) {
  final cells = [first];
  while (cursor.peek == rowSymbol) {
    // The `^` between cells is the row's: it separates the row's children.
    cursor.take();
    cells.add(parseColumnNode(cursor));
  }
  return RowNode(children: cells);
}
