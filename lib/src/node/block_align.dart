part of '../node.dart';

/// Where something sits across the width it is given.
///
/// Written as `<`, `=` or `>` directly after a separator, and nowhere else --
/// `List<String>` and `=>` are ordinary text. It lands on whatever that
/// separator opened: a [ColumnNode], a [TableCellNode] or a [TableNode].
///
/// A [RowNode] has none, and cannot: nothing opens a row, so there is no
/// marker to carry one. That fits what a row is -- it divides the width
/// between its cells rather than sitting in it, so there is no room left to
/// sit anywhere.
enum BlockAlign {
  start('<'),
  center('='),
  end('>');

  final String _char;
  const BlockAlign(this._char);

  static final Map<String, BlockAlign> _byChar = Map.unmodifiable({
    for (final align in BlockAlign.values) align._char: align,
  });

  /// Consumes the layout symbol at the cursor together with the markers
  /// written after it, and returns what they said.
  ///
  /// **Why the two are read as one.** Directly after a separator is the only
  /// place markers mean anything. Fusing the symbol and the markers *is*
  /// that rule; read apart, it would be stated nowhere.
  ///
  /// **Why the node cannot read them itself.** It does not know whether a
  /// separator came before it. `=>` at the start of a document is text, not
  /// a centre marker and an end marker, and a node reading its own markers
  /// would take it for the latter. Only the level that ate the symbol knows.
  ///
  /// **Why it sits here.** What comes back is an alignment, and the nodes it
  /// ends up on -- a column, a table, a table's cell -- share no ancestor
  /// closer than the root. The one thing they have in common is this.
  ///
  /// Null when no marker was written, which is not [start]: something that
  /// stated nothing is a different thing from something that asked for the
  /// start. A later marker overrides an earlier one, so `|<^>` ends up
  /// end-aligned.
  static BlockAlign? _takeSeparator(SourceCursor cursor) {
    cursor.take();

    BlockAlign? align;
    while (!cursor.isEnd) {
      final marker = _byChar[cursor.peek];
      if (marker == null) break;
      align = marker;
      cursor.take();
    }
    return align;
  }
}
