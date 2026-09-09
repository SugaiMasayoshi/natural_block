import '../horizontal_align.dart';
import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';
import 'separator.dart';

/// Reads one block or cell: the separator that opened it, if one is there,
/// and then everything up to the next `|` or `^`, which it leaves for whoever
/// those belong to.
///
/// [opener] is the separator that can open this one. A `|` for a block, since
/// that is what divides them; a `^` for a cell of a row, since that is what
/// divides those. The caller names it because only the caller knows which it
/// is in: `^a` at the start of a document is a row whose first cell is empty,
/// not a cell opened by that `^`.
///
/// Reads its own opener rather than being handed one, so the alignment written
/// on it is read where it is kept. Nothing above this has to hold an `align`
/// that belongs to a [ColumnNode]. And a block with no separator in front of
/// it -- the first of a document -- reads no markers at all, which is what
/// keeps `=>` at the start of a document ordinary text.
ColumnNode parseColumnNode(
  SourceCursor cursor, {
  String opener = columnSymbol,
}) {
  var align = HorizontalAlign.unstated;
  if (cursor.peek == opener) {
    cursor.take();
    align = takeMarkers(cursor);
  }

  // The newline against a boundary belongs to the boundary; see the rule in
  // `parse/document.dart`. This is the block's own start, not the
  // separator's -- a document beginning with a newline drops it too, and
  // there is no separator there at all.
  if (cursor.peek == '\n') cursor.take();

  final content = <ContentNode>[];

  // Reads straight through a `~`: a table is content, so it belongs to this
  // block rather than ending it.
  while (!cursor.isEnd && !separators.contains(cursor.peek)) {
    final before = cursor.position;
    final piece = parseContentNode(cursor);
    if (piece != null) content.add(piece);
    assert(
      cursor.position > before,
      'content parse made no progress at ${cursor.position}',
    );
  }

  return ColumnNode(children: content, align: align);
}
