import '../horizontal_align.dart';
import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';
import 'separator.dart';

/// Reads one cell: the separator that opened it, then everything up to the
/// next `^`, `|` or `~`.
///
/// Stops at all three. `~` is among them here and nowhere else, because
/// inside a table it is the delimiter that ends it.
///
/// [opener] is what can open this cell, named by the caller for the same
/// reason a block's is: a `|` opens a row, so it opens that row's first cell,
/// and a `^` opens each cell after it.
TableCellNode parseTableCellNode(
  SourceCursor cursor, {
  String opener = columnSymbol,
}) {
  var align = HorizontalAlign.unstated;
  if (cursor.peek == opener) {
    cursor.take();
    align = takeMarkers(cursor);
  }

  // A cell drops one blank line at its start, the same as a block; see the
  // rule in `parse/document.dart`.
  if (cursor.peek == '\n') cursor.take();

  final content = <ContentNode>[];

  while (!cursor.isEnd && !layoutSymbols.contains(cursor.peek)) {
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
