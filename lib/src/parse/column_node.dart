import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';

ColumnNode? parseColumnNode(SourceCursor cursor, HorizontalAlign align) {
  final children = <ContentNode>[];

  while (!cursor.isEnd) {
    final before = cursor.position;
    final content = parseContentNode(cursor, TextPlace.block);
    if (content != null) children.add(content);
    if (cursor.peek == '\n') {
      cursor.take();
      if (opensBlock(cursor.peek)) break;
    }
    assert(
      cursor.position > before,
      'column content parse made no progress at ${cursor.position}',
    );
  }

  return children.isEmpty ? null : ColumnNode(children: children, align: align);
}
