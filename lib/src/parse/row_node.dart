import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'content_node.dart';

/// A row from its opening `^` to the `^` that ends a line, or to the end of
/// the document.
///
/// [start] is where the row began, before its alignment marker.
RowNode parseRowNode(SourceCursor cursor, HorizontalAlign align, int start) {
  cursor.take();

  final cells = <ColumnNode>[];
  while (true) {
    final cellStart = cursor.position;
    final cellAlign = parseAlign(cursor);
    cells.add(
      ColumnNode(
        children: _parseCell(cursor),
        align: cellAlign == HorizontalAlign.unstated ? align : cellAlign,
        start: cellStart,
        end: cursor.position,
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

  return RowNode(children: cells, start: start, end: cursor.position);
}

List<ContentNode> _parseCell(SourceCursor cursor) {
  final children = <ContentNode>[];
  var atLineStart = true;
  while (!cursor.isEnd && cursor.peek != rowChar) {
    final before = cursor.position;
    final content = parseContentNode(
      cursor,
      TextPlace.cell,
      atLineStart: atLineStart,
    );
    if (content != null) children.add(content);
    atLineStart = cursor.peek == '\n';
    if (atLineStart) cursor.take();
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }
  return children;
}
