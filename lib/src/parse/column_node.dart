import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';
import 'layout_node.dart';

/// A block in [place], a document or a row's cell, up to the line where a
/// layout opens, or the `^` that ends its cell.
///
/// [start] is where the block began, before any alignment marker of its own.
ColumnNode? parseColumnNode(
  SourceCursor cursor,
  HorizontalAlign align,
  int start,
  TextPlace place,
) {
  final children = <ContentNode>[];
  bool endsCell() => place == TextPlace.rowCell && cursor.peek == rowChar;

  var atLineStart = true;
  while (!cursor.isEnd && !endsCell()) {
    final before = cursor.position;
    final content = parseContentNode(cursor, place, atLineStart: atLineStart);
    if (content != null) children.add(content);
    atLineStart = cursor.peek == '\n';
    if (atLineStart) {
      cursor.take();
      if (layoutOpensAt(cursor.source, cursor.position, place)) break;
    }
    assert(
      cursor.position > before,
      'column content parse made no progress at ${cursor.position}',
    );
  }

  if (children.isEmpty) return null;
  return ColumnNode(
    children: children,
    align: align,
    start: start,
    end: cursor.position,
  );
}
