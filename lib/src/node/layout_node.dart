part of '../node.dart';

/// How the things inside are arranged, and nothing else.
///
/// A [ColumnNode] stacks its content; a [RowNode] lays its cells across.
/// Neither is content itself -- they say where content goes. A document is
/// a stack of these.
///
/// A table is *not* one, even though it arranges rows inside itself. From
/// the outside it is a thing you place, sized to its own content, so it
/// belongs with the content it sits among. It is the one node that is
/// content on the outside and layout on the inside.
sealed class LayoutNode extends NaturalBlockNode {
  /// Reads whichever arrangement starts here, including the `|` that opened
  /// it.
  ///
  /// Every block reads the separator that opened it, and nothing at all for
  /// the first block of a document. That is why the markers land where they
  /// do: a `|` opens a cell, and the block becomes a row only if a `^` turns
  /// up afterwards. Read from the level above instead, the same marker would
  /// look like it described the row and then quietly settle on its first
  /// cell.
  ///
  /// The first cell is read before anything is known about what the block
  /// is, because the same text serves either reading. What the separator
  /// after it turns out to be decides who finishes the job, and the cell
  /// already read is handed on rather than re-read or re-labelled.
  ///
  /// Null when the block turned out to have nothing in it.
  static LayoutNode? _parse(SourceCursor cursor) {
    final align = cursor.peek == columnSymbol
        ? HorizontalAlign._takeSeparator(cursor)
        : HorizontalAlign.unstated;

    final first = ColumnNode._parse(cursor, align);
    if (cursor.peek == rowSymbol) return RowNode._parse(cursor, first);

    // An empty Column block is content that is not there, so it contributes
    // no node -- `左||右` is two blocks, not three.
    return first.children.isEmpty ? null : first;
  }
}
