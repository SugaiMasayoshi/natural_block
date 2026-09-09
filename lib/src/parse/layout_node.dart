import '../horizontal_align.dart';
import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';
import 'row_node.dart';
import 'separator.dart';

/// Reads whichever arrangement starts here, including the `|` that opened it.
///
/// That the `|` is read here is why an alignment marker lands on the cell it
/// opens rather than on the row that may form around it afterwards. Read one
/// level up, the same marker would look like it described the row and then
/// quietly settle on its first cell.
///
/// The first cell is read before anything is known about what the block is,
/// because the same text serves either reading. The separator after it
/// decides who finishes the job, and the cell already read is handed on
/// rather than re-read.
///
/// Null when the block turned out to have nothing in it.
LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final align = cursor.peek == columnSymbol
      ? takeSeparator(cursor)
      : HorizontalAlign.unstated;

  final first = parseColumnNode(cursor, align);
  if (cursor.peek == rowSymbol) return parseRowNode(cursor, first);

  // An empty Column block is content that is not there, so it contributes no
  // node -- `左||右` is two blocks, not three.
  return first.children.isEmpty ? null : first;
}
