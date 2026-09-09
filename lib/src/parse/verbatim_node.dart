import '../nodes.dart';
import '../source_cursor.dart';
import '../verbatim_region.dart';
import 'verbatim_span_node.dart';

/// Whether one of these opens at the cursor.
///
/// A region is a block when it was written on a line of its own, and a run
/// inside a line otherwise -- the same fence, told apart by where it sits.
/// Stated once and asked by both sides: the line that must not take it and
/// the block that must. If the two disagreed, neither would consume the fence
/// and the caller's loop would never advance.
///
/// The cheap half is asked first, so a fence written mid-line costs one
/// character rather than a search for the closing fence.
bool verbatimNodeOpensAt(SourceCursor cursor) =>
    (cursor.position == 0 || cursor.peekAt(-1) == '\n') &&
    verbatimSpanNodeOpensAt(cursor);

/// Consumes the region opening at the cursor, plus the newline written after
/// its closing fence -- the third of the boundaries in the rule in
/// `parse/document.dart`, and the only one this node can see.
VerbatimNode parseVerbatimNode(SourceCursor cursor) {
  final (text, end) = verbatimRegion(cursor.source, cursor.position);
  cursor.jumpTo(end);
  if (cursor.peek == '\n') cursor.take();
  return VerbatimNode(text: text);
}
