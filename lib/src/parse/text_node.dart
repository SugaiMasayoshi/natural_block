import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'inline_node.dart';

/// The runs up to the end of the line or a boundary. A line with nothing on
/// it before a cell's end is the cell's, not a blank line.
TextNode? parseTextNode(SourceCursor cursor, TextPlace place) {
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

  final endsLine = cursor.isEnd || cursor.peek == '\n';
  if (children.isEmpty && !endsLine) return null;
  return TextNode(
    children: children,
    start: start,
    end: children.lastOrNull?.end ?? start,
  );
}
