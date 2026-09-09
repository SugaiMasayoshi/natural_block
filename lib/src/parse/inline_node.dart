import '../nodes.dart';
import '../source_cursor.dart';
import 'text_span_node.dart';
import 'verbatim_span_node.dart';

/// Whether inline content other than a run of styled text starts at the
/// cursor.
///
/// The dispatch below, asked as a question -- see `parse/content_node.dart`
/// for why a run asks this rather than naming its siblings.
bool otherInlineStartsHere(SourceCursor cursor) =>
    verbatimSpanNodeOpensAt(cursor);

/// Reads whichever kind of inline content starts here, together with the
/// decoration state it leaves behind.
///
/// The same shape the layout and content dispatches have: the sealed
/// supertype decides which of its subtypes the source becomes. This one also
/// passes the decoration along, because a run's style is carried in from what
/// was written before it rather than found within it.
///
/// Null when the run turned out to be empty -- a cluster with no text after
/// it changes the style and contributes no node.
(InlineNode?, SpanDecoration) parseInlineNode(
  SourceCursor cursor,
  SpanDecoration style,
) {
  if (otherInlineStartsHere(cursor)) {
    return (parseVerbatimSpanNode(cursor), style);
  }
  return parseTextSpanNode(cursor, style);
}
