import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';
import 'separator.dart';

/// What ends a cell: the two separators, and the `~` that ends the table
/// around it.
///
/// That `~` is the one thing a cell stops at which a block reads through, and
/// it is a guard rather than a boundary -- it is what keeps a table from
/// nesting, because the content level never gets to see it.
const _endsCell = {columnSymbol, rowSymbol, tableSymbol};

/// Reads one cell: everything up to the next `^`, `|` or `~`, which it leaves
/// for the row or the table -- a separator belongs to the parent of the
/// things it separates.
///
/// Stops at all three. `~` is among them here and nowhere else, because
/// inside a table it is the delimiter that ends it.
TableCellNode parseTableCellNode(SourceCursor cursor) {
  final align = parseAlign(cursor);

  // A cell drops one blank line at its start, the same as a block; see the
  // rule in `parse/document.dart`.
  if (cursor.peek == '\n') cursor.take();

  final content = <ContentNode>[];

  while (!cursor.isEnd && !_endsCell.contains(cursor.peek)) {
    final before = cursor.position;
    final piece = parseContentNode(cursor);
    if (piece != null) content.add(piece);
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }

  return TableCellNode(children: content, align: align);
}
