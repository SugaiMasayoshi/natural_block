import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'inline_node.dart';

TextNode? parseTextNode(SourceCursor cursor, TextPlace place) {
  final start = cursor.position;
  final children = <InlineNode>[];
  var style = const SpanDecoration();

  int before;
  do {
    before = cursor.position;
    final (node, next) = parseInlineNode(cursor, style, place);
    style = next;
    if (node != null) children.add(node);
  } while (cursor.position > before);

  if (children.isEmpty) return null;
  return TextNode(children: children, start: start, end: cursor.position);
}
