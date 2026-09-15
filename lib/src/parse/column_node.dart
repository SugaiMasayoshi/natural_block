import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'content_node.dart';

ColumnNode parseColumnNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  final children = <ContentNode>[];
  if (cursor.peek == '\n') cursor.take();

  while (!cursor.isEnd && !layoutChars.contains(cursor.peek)) {
    final before = cursor.position;
    final content = parseContentNode(cursor);
    if (content != null) children.add(content);
    if (cursor.peek == '\n') cursor.take();
    assert(
      cursor.position > before,
      'column content parse made no progress at ${cursor.position}',
    );
  }

  return ColumnNode(children: children, align: align);
}
