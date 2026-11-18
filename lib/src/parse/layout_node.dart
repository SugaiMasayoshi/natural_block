import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'column_node.dart';
import 'row_node.dart';
import 'spacer_node.dart';

LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final start = cursor.position;
  if (parseSpacerNode(cursor, TextPlace.block) case final spacer?) {
    if (cursor.peek == '\n') cursor.take();
    return spacer;
  }
  final escapedSpacer =
      cursor.peek == escapeChar &&
      spacerAt(cursor.source, start + 1, TextPlace.block) != null;
  if (escapedSpacer) cursor.take();

  final align = parseAlign(cursor);
  if (cursor.peek == rowChar) return parseRowNode(cursor, align, start);
  final escapedRow = cursor.peek == escapeChar && cursor.peekAt(1) == rowChar;
  if (escapedRow) cursor.take();

  return parseColumnNode(cursor, align, start);
}
