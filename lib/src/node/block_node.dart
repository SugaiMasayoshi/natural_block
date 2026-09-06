part of '../node.dart';

sealed class BlockNode extends NaturalBlockNode {
  /// Consumes the layout symbol that opens the coming block, together with
  /// the markers written after it, and returns what they said.
  ///
  /// **Why the two are read as one.** That is the only place markers mean
  /// anything: `<`, `=` and `>` are ordinary text everywhere else, so
  /// `List<String>` and `=>` come through untouched. Fusing the symbol and
  /// the markers *is* that rule; read apart, it would be stated nowhere.
  ///
  /// **Why the block cannot read them itself.** It does not know whether a
  /// separator came before it. `=>` at the start of a document is text, not
  /// a centre marker and an end marker, and a block reading its own markers
  /// would take it for the latter. Only the level doing the arranging knows,
  /// which is why the answer arrives at [_parse] as an argument.
  ///
  /// **Why it sits on `BlockNode`.** Every separator it eats opens a block:
  /// [_parse] takes the `|` that opened this one, [TableNode] the `~` that
  /// opened it, [RowNode] the `^` that opens each cell after the first. What
  /// comes back is an alignment describing that block, which ends up in
  /// [ColumnNode.align] or [TableNode.align].
  ///
  /// Null when no marker was written, which is not [BlockAlign.start]: a
  /// block that stated nothing is a different thing from one that asked for
  /// the start. A later marker overrides an earlier one, so `|<^>` ends up
  /// end-aligned.
  static BlockAlign? _takeSeparator(SourceCursor cursor) {
    cursor.take();

    BlockAlign? align;
    while (!cursor.isEnd) {
      final marker = BlockAlign.byChar[cursor.peek];
      if (marker == null) break;
      align = marker;
      cursor.take();
    }
    return align;
  }

  /// Reads whichever block starts here, including the separator that opened
  /// it.
  ///
  /// The sealed supertype decides which of its subtypes the source becomes,
  /// the same shape [ContentNode] and [InlineNode] have.
  ///
  /// Every block reads the separator that opened it -- a `~` by way of the
  /// table it opens, a `|` here, and nothing at all for the first block of
  /// a document. That is why the markers land where they do: a `|` opens a
  /// cell, and the block becomes a row only if a `^` turns up afterwards.
  /// Read from the level above instead, the same marker would look like it
  /// described the row and then quietly settle on its first cell.
  ///
  /// The first cell is read before anything is known about what the block
  /// is, because the same text serves either reading. What the separator
  /// after it turns out to be decides who finishes the job, and the cell
  /// already read is handed on rather than re-read or re-labelled.
  ///
  /// Null when the block turned out to have nothing in it.
  static BlockNode? _parse(SourceCursor cursor) {
    if (cursor.peek == tableSymbol) return TableNode._parse(cursor);

    final align = cursor.peek == columnSymbol ? _takeSeparator(cursor) : null;

    final first = ColumnNode._parse(cursor, align);
    if (cursor.peek == rowSymbol) return RowNode._parse(cursor, first);

    // An empty Column block is content that is not there, so it contributes
    // no node -- `左||右` is two blocks, not three.
    return first.children.isEmpty ? null : first;
  }
}
