import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_cell_node.dart';

/// Reads one row, whose `|` its first cell reads.
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
    final before = cursor.position;
    // The cell this `^` opens is read whatever follows, the end of the table
    // included. An empty cell is a position the grid keeps.
    cells.add(parseTableCellNode(cursor, opener: rowSymbol));
    assert(
      cursor.position > before,
      'table cell parse made no progress at ${cursor.position}',
    );
  }

  if (cells.length == 1 && cells.single.children.isEmpty) return null;
  return TableRowNode(children: cells);
}
