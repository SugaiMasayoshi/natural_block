import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';
import 'row_node.dart';

LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final first = parseColumnNode(cursor);
  if (cursor.peek == rowChar) return parseRowNode(cursor, first);

  return first.children.isEmpty ? null : first;
}
