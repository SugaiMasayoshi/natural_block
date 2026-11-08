import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';

/// [start] is where the block began, before its alignment marker.
ColumnNode? parseColumnNode(
  SourceCursor cursor,
  HorizontalAlign align,
  int start,
) {
  final children = <ContentNode>[];

  var atLineStart = true;
  while (!cursor.isEnd) {
    final before = cursor.position;
    final content = parseContentNode(
      cursor,
      TextPlace.block,
      atLineStart: atLineStart,
    );
    if (content != null) children.add(content);
    atLineStart = cursor.peek == '\n';
    if (atLineStart) {
      cursor.take();
      if (opensBlock(cursor.peek)) break;
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
