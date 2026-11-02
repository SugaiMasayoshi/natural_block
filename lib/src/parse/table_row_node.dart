import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_cell_node.dart';

/// A row from its opening `^`, which a line may leave out, to the `^` that
/// ends a line, or to the end of the table or the document.
TableRowNode parseTableRowNode(SourceCursor cursor) {
  if (cursor.peek == rowChar) cursor.take();

  final cells = [parseTableCellNode(cursor)];
  while (_takeSeparator(cursor)) {
    cells.add(parseTableCellNode(cursor));
  }
  return TableRowNode(children: cells);
}

/// Reads the `^` after a cell, and whether another cell follows it.
bool _takeSeparator(SourceCursor cursor) {
  if (cursor.peek != rowChar) return false;
  cursor.take();
  if (cursor.peek == '\n') {
    cursor.take();
    return false;
  }
  return !cursor.isEnd && cursor.peek != tableChar;
}
