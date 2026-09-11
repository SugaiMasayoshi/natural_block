import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'inline_node.dart';

/// Reads one run of inline content, stopping in front of anything that is not
/// its own and consuming none of it, so the caller can look at the cursor and
/// decide what comes next.
TextNode parseTextNode(SourceCursor cursor) {
  final children = <InlineNode>[];
  var style = const SpanDecoration();

  while (true) {
    final before = cursor.position;
    final (node, next) = parseInlineNode(cursor, style);
    style = next;
    if (node != null) children.add(node);
    if (cursor.position == before) break;
  }

  return TextNode(children: children);
}
