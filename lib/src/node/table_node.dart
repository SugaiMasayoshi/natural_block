part of '../node.dart';

final class TableNode extends BlockNode {
  /// The rows as the source wrote them. A row may be shorter than the table
  /// is wide; it is not padded here, because the author wrote no cell there.
  final List<RowNode> children;

  /// What each column declared, and by its length how wide the table is.
  ///
  /// Two facts in one list because they come from one place: a column exists
  /// because some row had a cell at that position, and its alignment is what
  /// that row's cell stated -- which may be nothing.
  ///
  /// This is where a table's column alignment lives, rather than being
  /// stamped onto every cell. A cell's own `align` therefore keeps meaning
  /// "what this cell stated", and a consumer resolves the two:
  ///
  /// ```dart
  /// final effective = cell.align ?? table.columns[i];
  /// ```
  ///
  /// Read from the rows rather than passed in, so a hand-built table cannot
  /// disagree with itself. Computed once, on first use.
  late final List<BlockAlign?> columns = _columns(children);

  /// The alignment written for the table itself, or null when none was.
  final BlockAlign? align;

  TableNode({this.children = const [], this.align});

  /// Reads the run of rows between the `~` that opened the table and the one
  /// that ends it, which it stops in front of rather than consuming.
  ///
  /// Everything in between is the table's, so there is nothing to hand back.
  /// Null when no row had any content.
  static TableNode? _parse(SourceCursor cursor, BlockAlign? align) {
    final rows = <RowNode>[];

    // What the `|` that opened the coming row said about its first cell.
    // The markers on the `~` that opened the table describe the table, not
    // its first cell, so the first row starts with nothing stated.
    BlockAlign? firstCellAlign;

    while (true) {
      // A table reads a block exactly as the document does, including the
      // rule that an empty one contributes nothing -- which is what lets
      // every row be written with a leading `|`. The one difference is what
      // a block that read no `^` becomes: outside a table it stays a column,
      // here it is still a row, of a single cell.
      switch (BlockNode._parse(cursor, firstCellAlign)) {
        case final RowNode row:
          rows.add(row);
        case final ColumnNode cell:
          rows.add(RowNode(children: [cell]));
        case _:
          break;
      }

      if (cursor.isEnd) break;
      if (cursor.peek == tableSymbol) break;
      firstCellAlign = BlockNode._takeSeparator(cursor);
    }

    if (rows.isEmpty) return null;
    return TableNode(align: align, children: rows);
  }

  /// What each column declared, taken from the first row that reached it.
  ///
  /// For the ordinary table -- whose first row is its widest -- that is just
  /// "the first row". A later row that is wider than every row before it
  /// declares the columns it adds.
  static List<BlockAlign?> _columns(List<RowNode> rows) {
    final columns = <BlockAlign?>[];
    for (final row in rows) {
      for (var i = columns.length; i < row.children.length; i++) {
        columns.add(row.children[i].align);
      }
    }
    return columns;
  }

  @override
  String toString() =>
      'TableNode(children: $children, columns: $columns, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}
