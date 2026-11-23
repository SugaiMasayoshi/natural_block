import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'column_node.dart';
import 'spacer_node.dart';

/// A row from its opening `^` to the `^` that ends a line, or to the end of
/// the document.
///
/// [start] is where the row began, before its alignment marker.
RowNode parseRowNode(SourceCursor cursor, HorizontalAlign align, int start) {
  cursor.take();

  final cells = <CellNode>[];
  while (true) {
    final cellStart = cursor.position;
    final cellAlign = parseAlign(cursor);
    cells.add(
      _parseCell(
        cursor,
        cellAlign == HorizontalAlign.unstated ? align : cellAlign,
        cellStart,
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

/// A cell up to the `^` that ends it: blocks of content, cut where a line
/// of `|` alone stands a spacer between them.
///
/// [start] is where the cell began, before its alignment marker.
CellNode _parseCell(SourceCursor cursor, HorizontalAlign align, int start) {
  final children = <FlatLayoutNode>[];
  while (!cursor.isEnd && cursor.peek != rowChar) {
    if (parseSpacerNode(cursor, TextPlace.rowCell) case final spacer?) {
      children.add(spacer);
      if (cursor.peek == '\n') cursor.take();
      continue;
    }
    final blockStart = children.isEmpty ? start : cursor.position;
    final block = parseColumnNode(cursor, align, blockStart, TextPlace.rowCell);
    if (block != null) children.add(block);
  }

  return CellNode(children: children, start: start, end: cursor.position);
}
