import '../horizontal_align.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'content_node.dart';
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
  var contents = <ContentNode>[];
  var blockStart = start;
  void endBlock(int end) {
    if (contents.isNotEmpty) {
      children.add(
        ColumnNode(
          children: contents,
          align: align,
          start: blockStart,
          end: end,
        ),
      );
    }
    contents = [];
  }

  var atLineStart = true;
  while (!cursor.isEnd && cursor.peek != rowChar) {
    final before = cursor.position;
    if (atLineStart) {
      if (parseSpacerNode(cursor, TextPlace.rowCell) case final spacer?) {
        endBlock(before);
        children.add(spacer);
        if (cursor.peek == '\n') cursor.take();
        blockStart = cursor.position;
        continue;
      }
      final escapedSpacer =
          cursor.peek == escapeChar &&
          spacerAt(cursor.source, cursor.position + 1, TextPlace.rowCell) !=
              null;
      if (escapedSpacer) cursor.take();
    }

    final content = parseContentNode(
      cursor,
      TextPlace.rowCell,
      atLineStart: atLineStart,
    );
    if (content != null) contents.add(content);
    atLineStart = cursor.peek == '\n';
    if (atLineStart) cursor.take();
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }
  endBlock(cursor.position);

  return CellNode(children: children, start: start, end: cursor.position);
}
