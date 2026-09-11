import '../nodes.dart';
import '../source_cursor.dart';
import 'verbatim_region.dart';

/// Whether a region opens at the cursor at all -- block or inline.
///
/// Not the same as "the cursor is on a backtick": an opening fence with no
/// closing one opens nothing, and is ordinary text. The character is checked
/// before the search so that prose settles the question without one --
/// removing that check doubled the parse time of a document with no
/// backticks.
bool verbatimRegionOpensAt(SourceCursor cursor) =>
    cursor.peek == verbatimFenceChar &&
    verbatimRegionEnd(cursor.source, cursor.position) != -1;

/// Whether the fence at the cursor was written on a line of its own, which is
/// what makes the region a block rather than a run inside a line.
///
/// The one thing about a region that its two kinds disagree on, so it is
/// stated once and each kind reads it the way round it needs.
bool verbatimRegionIsBlock(SourceCursor cursor) =>
    cursor.position == 0 || cursor.peekAt(-1) == '\n';

/// Whether one of these opens at the cursor.
///
/// A fence on a line of its own is not one: that is a [VerbatimNode], and
/// saying so here is what lets a run of text stop in front of it by the same
/// rule it stops in front of everything else -- because it is not its own.
bool verbatimSpanNodeOpensAt(SourceCursor cursor) =>
    verbatimRegionOpensAt(cursor) && !verbatimRegionIsBlock(cursor);

/// Consumes the region opening at the cursor.
///
/// Null when the region held nothing: an empty pair of fences styles no text,
/// so there is nothing to draw monospaced.
VerbatimSpanNode? parseVerbatimSpanNode(SourceCursor cursor) {
  final (text, end) = verbatimRegion(cursor.source, cursor.position);
  cursor.jumpTo(end);
  return text.isEmpty ? null : VerbatimSpanNode(text: text);
}
