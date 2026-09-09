import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';

/// Reads one cell or block: everything up to the next `|` or `^`, which it
/// leaves for whoever those belong to -- `^` divides cells and is the row's,
/// `|` divides blocks and is the document's or the table's.
///
/// Decides only what kind of child comes next, by looking at the cursor. Each
/// child reads itself and stops before anything that is not its own.
ColumnNode parseColumnNode(SourceCursor cursor, HorizontalAlign align) {
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
