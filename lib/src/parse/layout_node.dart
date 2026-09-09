import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';
import 'row_node.dart';

/// Reads whichever arrangement starts here.
///
/// Decides only that: which of the two a block turns out to be. The block
/// itself reads the `|` that opened it and whatever alignment was written on
/// it, because a [RowNode] has neither and a [ColumnNode] has both.
///
/// The first cell is read before anything is known about what the block is,
/// because the same text serves either reading. The separator after it
/// decides who finishes the job, and the cell already read is handed on
/// rather than re-read.
///
/// Null when the block turned out to have nothing in it.
LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final first = parseColumnNode(cursor);
  if (cursor.peek == rowSymbol) return parseRowNode(cursor, first);

  // An empty Column block is content that is not there, so it contributes no
  // node -- `左||右` is two blocks, not three.
  return first.children.isEmpty ? null : first;
}
