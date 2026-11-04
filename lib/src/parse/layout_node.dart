import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'column_node.dart';
import 'row_node.dart';

LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  if (cursor.peek == rowChar) return parseRowNode(cursor, align);
  final escapedRow = cursor.peek == escapeChar && cursor.peekAt(1) == rowChar;
  if (escapedRow) cursor.take();

  return parseColumnNode(cursor, align);
}
