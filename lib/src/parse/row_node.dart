import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';

RowNode parseRowNode(SourceCursor cursor, ColumnNode first) {
  final cells = [first];
  while (cursor.peek == rowSymbol) {
    final before = cursor.position;

    cells.add(parseColumnNode(cursor, opener: rowSymbol));

    assert(
      cursor.position > before,
      'row cell parse made no progress at ${cursor.position}',
    );
  }
  return RowNode(children: cells);
}
