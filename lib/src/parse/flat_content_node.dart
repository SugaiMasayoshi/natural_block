import '../nodes.dart';
import '../source_cursor.dart';
import 'raw.dart';
import 'text_node.dart';

FlatContentNode? parseFlatContentNode(SourceCursor cursor) {
  if (rawBlockAt(cursor.source, cursor.position)) return parseRawNode(cursor);

  return parseTextNode(cursor);
}
