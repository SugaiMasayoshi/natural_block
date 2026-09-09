import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';
import 'inline_node.dart';

/// Whether a run of inline content ends at the cursor: the block's own
/// separator, a verbatim region written on a line of its own, or the end of
/// the source.
bool textEndsHere(SourceCursor cursor) =>
    cursor.isEnd ||
    separators.contains(cursor.peek) ||
    otherContentStartsHere(cursor);

/// Drops the newline written against the end of this run; see the rule in
/// `parse/document.dart`.
///
/// Here rather than in the span that read it, because a span cannot know:
/// whether the thing it stopped at ends this whole run is settled one level
/// up, after it has returned. And it is not its rule to apply -- "content
/// does not end with a newline" is about the run, which is this node.
///
/// The caller checks that the text actually reaches the boundary first.
void _dropNewlineAtBoundary(List<InlineNode> children) {
  if (children.isEmpty) return;
  final last = children.last;
  if (last is! TextSpanNode || !last.text.endsWith('\n')) return;

  final text = last.text.substring(0, last.text.length - 1);
  if (text.isEmpty) {
    children.removeLast();
  } else {
    children[children.length - 1] = TextSpanNode(
      text: text,
      decoration: last.decoration,
    );
  }
}

/// Reads one run of inline content, stopping in front of anything that is not
/// its own: a separator that belongs to the block, or a verbatim region
/// written on a line of its own.
///
/// Neither is consumed. A node never eats what belongs to something else, so
/// the caller can look at the cursor and decide what comes next.
TextNode parseTextNode(SourceCursor cursor) {
  final children = <InlineNode>[];
  var style = const SpanDecoration();

  // Where the text read so far ends, which is not always where the run does:
  // markup that produces no node moves the cursor past it.
  var textEnd = cursor.position;

  while (!textEndsHere(cursor)) {
    final before = cursor.position;
    final (node, next) = parseInlineNode(cursor, style);
    style = next;
    if (node != null) {
      children.add(node);
      textEnd = cursor.position;
    }
    // A child that reads nothing where the loop expects content would spin
    // here forever. The mistake is silent otherwise -- it hangs rather than
    // producing a wrong tree -- so it is worth saying out loud.
    assert(
      cursor.position > before,
      'inline parse made no progress at ${cursor.position}',
    );
  }

  // Only when the text reaches the boundary. `text\n:*` wrote a cluster
  // between them, and a cluster is inline -- it does not put anything on a
  // line of its own -- so that newline is ordinary content.
  if (textEnd == cursor.position) _dropNewlineAtBoundary(children);
  return TextNode(children: children);
}
