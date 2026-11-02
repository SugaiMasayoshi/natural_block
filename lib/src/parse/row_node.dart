import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'content_node.dart';

/// A row from its opening `^` to the `^` that ends a line, or to the end of
/// the document.
RowNode parseRowNode(SourceCursor cursor, HorizontalAlign align) {
  cursor.take();

  final cells = <ColumnNode>[];
  while (true) {
    final cellAlign = parseAlign(cursor);
    cells.add(
      ColumnNode(
        children: _parseCell(cursor),
        align: cellAlign == HorizontalAlign.unstated ? align : cellAlign,
      ),
    );
    if (cursor.isEnd) break;

    cursor.take();
    if (cursor.isEnd) break;
    if (cursor.peek == '\n') {
      cursor.take();
      break;
    }
  }

  return RowNode(children: cells);
}

List<ContentNode> _parseCell(SourceCursor cursor) {
  final children = <ContentNode>[];
  while (!cursor.isEnd && cursor.peek != rowChar) {
    final before = cursor.position;
    final content = parseContentNode(cursor, TextPlace.cell);
    if (content != null) children.add(content);
    if (cursor.peek == '\n') cursor.take();
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }
  return children;
}
