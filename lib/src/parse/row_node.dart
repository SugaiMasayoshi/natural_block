import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';

RowNode parseRowNode(SourceCursor cursor, ColumnNode first) {
  final cells = [first];
  while (cursor.peek == rowChar) {
    cursor.take();
    cells.add(parseColumnNode(cursor));
  }
  return RowNode(children: cells);
}
