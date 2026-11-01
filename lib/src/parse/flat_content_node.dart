import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'raw.dart';
import 'text_node.dart';

FlatContentNode? parseFlatContentNode(SourceCursor cursor, TextPlace place) {
  if (rawBlockAt(cursor.source, cursor.position)) return parseRawNode(cursor);

  return parseTextNode(cursor, place);
}
