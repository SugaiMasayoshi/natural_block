import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_cell_node.dart';

/// Reads one row. The `|` in front of it is the table's, which separates
/// rows.
///
/// A table's `|` always opens a row, so a lone cell is a row of one -- the
/// only thing a table reads differently from a document, where the same text
/// would stay a column.
///
/// Null when the row had nothing in it, which is what lets every row be
/// written with a leading `|`.
TableRowNode? parseTableRowNode(SourceCursor cursor) {
  final cells = [parseTableCellNode(cursor)];
  while (cursor.peek == rowSymbol) {
    // The `^` between cells is the row's. The cell after it is read whatever
    // follows, the end of the table included: an empty cell is a position the
    // grid keeps.
    cursor.take();
    cells.add(parseTableCellNode(cursor));
  }

  if (cells.length == 1 && cells.single.children.isEmpty) return null;
  return TableRowNode(children: cells);
}
