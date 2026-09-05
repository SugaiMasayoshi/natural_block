import '../source_cursor.dart';

const String verbatimFenceChar = '`';

/// Where the region opening at [openIndex] ends, or -1 when none opens there.
///
/// A fence is however many backticks were written in a row, and it closes on
/// the same number. An opening fence with no closing one opens nothing: the
/// backticks are ordinary text.
///
/// Builds no string, deliberately. Of the four levels that meet a fence,
/// three only ask *whether* a region is here and one consumes it; asking used
/// to cost the same as consuming, because both went through the same function
/// and it always cut the text out.
int verbatimRegionEnd(String source, int openIndex) {
  if (openIndex >= source.length || source[openIndex] != verbatimFenceChar) {
    return -1;
  }

  var fence = 0;
  while (openIndex + fence < source.length &&
      source[openIndex + fence] == verbatimFenceChar) {
    fence += 1;
  }

  final closerStart = source.indexOf(
    verbatimFenceChar * fence,
    openIndex + fence,
  );
  return closerStart == -1 ? -1 : closerStart + fence;
}

/// The content of the region that opens at [openIndex] and ends at [end].
///
/// The newline written against either fence belongs to the fence rather than
/// to the content, so a region written on its own lines does not draw as a
/// blank line, its text, and another blank line.
String verbatimRegionText(String source, int openIndex, int end) {
  var fence = 0;
  while (source[openIndex + fence] == verbatimFenceChar) {
    fence += 1;
  }

  var text = source.substring(openIndex + fence, end - fence);
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  return text;
}

/// How a cursor walks over a verbatim region.
///
/// An extension rather than part of the cursor, because this is grammar: a
/// region becomes a node, and a fence is the only markup whose meaning cannot
/// be settled by looking at the character under the cursor. It drives the
/// cursor through the same public operations any node uses.
///
/// Three of the four levels that meet a fence only ask whether it opens a
/// region, and each asks about the same position -- a child stops in front of
/// what is not its own, and its owner then asks again. The answer used to be
/// remembered inside the cursor, which meant the cursor held the one piece of
/// this language's grammar it had no other reason to know. Asking three times
/// instead costs three searches and no allocation, which measured at about a
/// tenth of a millisecond on a document of fifteen thousand characters.
extension VerbatimRegions on SourceCursor {
  /// Whether a verbatim region opens here. Asks without consuming, so a node
  /// can decide whether the region belongs to it before touching it.
  ///
  /// Not the same as "the cursor is on a backtick": an opening fence with no
  /// closing one opens nothing, and is ordinary text.
  ///
  /// The character is checked here as well as inside [verbatimRegionEnd], so
  /// that prose -- which is every character of most documents -- settles the
  /// question without a call. Removing this line doubled the parse time of a
  /// document containing no backticks at all.
  bool get atVerbatimFence =>
      peek == verbatimFenceChar && verbatimRegionEnd(source, position) != -1;

  /// Whether the region opening here was written on a line of its own, and
  /// so is a block rather than a run inside a line.
  ///
  /// Stated once, and asked by both sides: the line that must not take it
  /// and the block that must. If the two disagreed, neither would consume
  /// the fence and the caller's loop would never advance.
  ///
  /// The cheap half is asked first: a fence written mid-line is never a
  /// block, and settling that costs one character rather than a search for
  /// the closing fence.
  bool get atBlockRegion =>
      (position == 0 || peekAt(-1) == '\n') && atVerbatimFence;

  /// Consumes the region opening at the cursor and returns its content.
  String takeVerbatim() {
    final end = verbatimRegionEnd(source, position);
    final text = verbatimRegionText(source, position, end);
    jumpTo(end);
    return text;
  }
}
