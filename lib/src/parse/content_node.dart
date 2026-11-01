import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'flat_content_node.dart';
import 'table_node.dart';

ContentNode? parseContentNode(SourceCursor cursor, TextPlace place) {
  if (cursor.peek == tableChar) return parseTableNode(cursor);
  return parseFlatContentNode(cursor, place);
}
