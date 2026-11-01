import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'column_node.dart';
import 'row_node.dart';

LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  if (cursor.peek == rowChar) return parseRowNode(cursor, align);
  if (cursor.peek == escapeChar && cursor.peekAt(1) == rowChar) cursor.take();

  return parseColumnNode(cursor, align);
}
