import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'raw.dart';
import 'text_node.dart';

FlatContentNode? parseFlatContentNode(SourceCursor cursor) {
  if (cursor.peek == rawChar && cursor.atLineStart) return parseRawNode(cursor);

  final text = parseTextNode(cursor);
  return text.children.isEmpty ? null : text;
}
