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
  /// **Why it sits on `BlockNode` even so.** Eating the symbol belongs to
  /// whoever is arranging -- the document between blocks, a table between
  /// rows, a row between cells -- and those three share no supertype and no
  /// common loop. What they produce does: an alignment describing the block
  /// about to be read, which ends up in [ColumnNode.align] or
  /// [TableNode.align]. The result is a fact about a block, so it is named
  /// where blocks are.
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

  /// Reads whichever block starts here, given the alignment the separator
  /// that opened it stated.
  ///
  /// The sealed supertype decides which of its subtypes the source becomes,
  /// the same shape [ContentNode] and [InlineNode] have. A `~` opens a
  /// table, and the table reads its own delimiters.
  ///
  /// Otherwise the first cell is read before anything is known about what
  /// the block is, because the same text serves either reading. What the
  /// separator after it turns out to be decides who finishes the job, and
  /// the cell already read is handed on rather than re-read or re-labelled.
  ///
  /// Null when the block turned out to have nothing in it.
  static BlockNode? _parse(SourceCursor cursor, BlockAlign? align) {
    if (cursor.peek == tableSymbol) return TableNode._parse(cursor);

    final first = ColumnNode._parse(cursor, align);
    final row = RowNode._parse(cursor, first);
    if (row != null) return row;

    // An empty Column block is content that is not there, so it contributes
    // no node -- `左||右` is two blocks, not three.
    return first.children.isEmpty ? null : first;
  }
}
