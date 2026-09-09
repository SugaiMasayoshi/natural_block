import '../horizontal_align.dart';
import '../source_cursor.dart';

/// The three alignments that can be written. [HorizontalAlign.unstated] is
/// absent because there is no character for it -- that is what it means.
const Map<String, HorizontalAlign> _byChar = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

/// Consumes the layout symbol at the cursor together with the markers
/// written after it, and returns what they said.
///
/// **Why the two are read as one.** Directly after a separator is the only
/// place markers mean anything. Fusing the symbol and the markers *is* that
/// rule; read apart, it would be stated nowhere.
///
/// **Why the node cannot read them itself.** It does not know whether a
/// separator came before it. `=>` at the start of a document is text, not a
/// centre marker and an end marker, and a node reading its own markers would
/// take it for the latter. Only the level that ate the symbol knows.
///
/// **Why it sits on its own.** The nodes it ends up on -- a column, a table,
/// a table's cell -- share no ancestor closer than the root.
///
/// A later marker overrides an earlier one, so `|<>` ends up end-aligned --
/// the rule a decoration cluster already has, where `:!%` is success.
///
/// A `^` is not a marker, so it ends the run of them and opens a cell of its
/// own: `|<^>a` is a row, not an end-aligned block.
HorizontalAlign takeSeparator(SourceCursor cursor) {
  cursor.take();

  var align = HorizontalAlign.unstated;
  while (!cursor.isEnd) {
    final marker = _byChar[cursor.peek];
    if (marker == null) break;
    align = marker;
    cursor.take();
  }
  return align;
}
