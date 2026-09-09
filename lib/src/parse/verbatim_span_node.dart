import '../nodes.dart';
import '../source_cursor.dart';
import '../verbatim_region.dart';

/// Whether one of these opens at the cursor.
///
/// Asked by the levels that must *not* take the region as well as by the one
/// that must -- the run stops in front of it, the inline dispatch hands it
/// here -- so the question belongs to the node being asked about rather than
/// to the cursor, which has no reason to know what a backtick is.
///
/// Not the same as "the cursor is on a backtick": an opening fence with no
/// closing one opens nothing, and is ordinary text. The character is checked
/// before the search so that prose -- which is every character of most
/// documents -- settles the question without a call; removing that check
/// doubled the parse time of a document containing no backticks.
bool verbatimSpanNodeOpensAt(SourceCursor cursor) =>
    cursor.peek == verbatimFenceChar &&
    verbatimRegionEnd(cursor.source, cursor.position) != -1;

/// Consumes the region opening at the cursor.
///
/// Null when the region held nothing: an empty pair of fences styles no text,
/// so there is nothing to draw monospaced.
VerbatimSpanNode? parseVerbatimSpanNode(SourceCursor cursor) {
  final (text, end) = verbatimRegion(cursor.source, cursor.position);
  cursor.jumpTo(end);
  return text.isEmpty ? null : VerbatimSpanNode(text: text);
}
