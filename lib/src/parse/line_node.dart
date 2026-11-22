import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'inline_node.dart';

/// The runs up to the end of the line, a boundary or a raw block.
LineNode parseLineNode(SourceCursor cursor, TextPlace place) {
  final start = cursor.position;
  final children = <InlineNode>[];
  var style = const SpanDecoration();

  int before;
  do {
    before = cursor.position;
    final InlineNode? node;
    (node, style) = parseInlineNode(cursor, style, place);
    if (node != null) children.add(node);
  } while (cursor.position > before);

  return LineNode(
    children: children,
    start: start,
    end: children.lastOrNull?.end ?? start,
  );
}
