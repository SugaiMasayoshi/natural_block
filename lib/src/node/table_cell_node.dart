part of '../node.dart';

/// One cell of a table.
///
/// Holds what a block holds, and yet never another table -- not because the
/// reading below skips that branch, but because it never gets that far. A
/// cell stops at `~`, so the `~` inside a table is always the one that ends
/// it and never one that opens another. Nesting is ruled out by where the
/// cell stops, which is the one line of it that differs from a column.
///
/// Not a [ColumnNode], though it stacks its content the same way. A column
/// reads through a `~` -- a table is content, so a block keeps going after
/// one -- while a cell has to stop at it.
final class TableCellNode extends NaturalBlockNode {
  final List<ContentNode> children;

  /// What this cell stated, which is also what its column declares when it
  /// is the first row to reach that position. Null when it stated nothing.
  final BlockAlign? align;

  TableCellNode({this.children = const [], this.align});

  /// Reads one cell: everything up to the next `^`, `|` or `~`.
  ///
  /// Stops at all three. `~` is among them here and nowhere else, because
  /// inside a table it is the delimiter that ends it.
  static TableCellNode _parse(SourceCursor cursor, BlockAlign? align) {
    // A cell drops one blank line at its start, the same as a block; see the
    // rule in `node.dart`.
    if (cursor.peek == '\n') cursor.take();

    final content = <ContentNode>[];

    while (!cursor.isEnd && !layoutSymbols.contains(cursor.peek)) {
      final before = cursor.position;
      final piece = ContentNode._parse(cursor);
      if (piece != null) content.add(piece);
      assert(
        cursor.position > before,
        'cell content parse made no progress at ${cursor.position}',
      );
    }

    return TableCellNode(children: content, align: align);
  }

  @override
  String toString() => 'TableCellNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableCellNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}
