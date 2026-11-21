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

  if (children.isNotEmpty) {
    return TextNode(children: children, start: start, end: cursor.position);
  }

  // A blank line with no text beside it to hold its line break.
  final at = cursor.position;
  final startsLine = at == 0 || cursor.source[at - 1] == '\n';
  if (cursor.peek != '\n' || !startsLine) return null;
  return TextNode(
    children: [TextSpanNode(text: '', start: at, end: at)],
    start: at,
    end: at,
  );
}
