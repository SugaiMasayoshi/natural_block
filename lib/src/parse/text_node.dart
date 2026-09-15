import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'inline_node.dart';

TextNode parseTextNode(SourceCursor cursor) {
  final children = <InlineNode>[];
  var style = const SpanDecoration();

  int before;
  do {
    before = cursor.position;
    final (node, next) = parseInlineNode(cursor, style);
    style = next;
    if (node != null) children.add(node);
  } while (cursor.position > before);

  return TextNode(children: children);
}
