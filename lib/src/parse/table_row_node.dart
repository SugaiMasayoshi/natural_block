import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'separator.dart';
import 'table_cell_node.dart';

/// Reads one row, including the `|` that opened it.
///
/// A table's `|` always opens a row, so a lone cell is a row of one -- the
/// only thing a table reads differently from a document, where the same text
/// would stay a column.
///
/// Null when the row had nothing in it, which is what lets every row be
/// written with a leading `|`.
TableRowNode? parseTableRowNode(SourceCursor cursor) {
  final align = cursor.peek == columnSymbol
      ? takeSeparator(cursor)
      : HorizontalAlign.unstated;

  final cells = [parseTableCellNode(cursor, align)];
  while (cursor.peek == rowSymbol) {
    // The cell this `^` opens is read whatever follows, the end of the table
    // included. An empty cell is a position the grid keeps.
    cells.add(parseTableCellNode(cursor, takeSeparator(cursor)));
  }

  if (cells.length == 1 && cells.single.children.isEmpty) return null;
  return TableRowNode(children: cells);
}
