import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';

/// Continues a block that turned out to be a row, given the cell already
/// read.
///
/// Called only with the cursor on a `^`: the level above tests, this
/// assumes. Returning null for "not a row" would have put that answer down
/// the same channel every other parse uses for "it held nothing".
///
/// Tests for each `^` and lets the cell it opens eat it, the same way a block
/// eats its own `|`. The `|` that ends the row is left for whoever arranges
/// blocks.
RowNode parseRowNode(SourceCursor cursor, ColumnNode first) {
  final cells = [first];
  while (cursor.peek == rowSymbol) {
    final before = cursor.position;
    // The cell this `^` opens is read whatever follows, the end of the
    // source included: an empty cell is a position the layout keeps, and the
    // row must not change meaning as the author types past it.
    cells.add(parseColumnNode(cursor, opener: rowSymbol));
    // This loop advances only because the cell eats the `^` it tested for.
    // A cell that did not would spin here rather than build a wrong tree.
    assert(
      cursor.position > before,
      'row cell parse made no progress at ${cursor.position}',
    );
  }
  return RowNode(children: cells);
}
