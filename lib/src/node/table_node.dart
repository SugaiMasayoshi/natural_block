part of '../node.dart';

/// A grid, written between a pair of `~`.
///
/// Content, not layout: from the outside it is a thing you place, sized to
/// its own rows rather than to the width it is given. Inside it arranges,
/// which makes it the one node with a foot on each side.
final class TableNode extends ContentNode {
  /// The rows as the source wrote them. A row may be shorter than the table
  /// is wide; it is not padded here, because the author wrote no cell there.
  final List<TableRowNode> children;

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
  ///
  /// Where the table sits inside its block, which is not the same question
  /// as [ColumnNode.align] -- that one says how a block arranges everything
  /// it holds. `|=` centres the text and the table together; `~=` centres
  /// only the table.
  final BlockAlign? align;

  TableNode({this.children = const [], this.align});

  /// Reads the table that opens at the cursor, both `~` included.
  ///
  /// Each delimiter is the table's own -- the one that opens it and the one
  /// that ends it -- exactly as a verbatim region owns both of its fences. A
  /// `~` wraps rather than separates, and what wraps belongs to what it
  /// wraps. It has to: a table is sized to its own content, so it must know
  /// where it stops.
  ///
  /// Null when no row had any content.
  static TableNode? _parse(SourceCursor cursor) {
    // The markers on the opening `~` describe the table itself.
    final align = LayoutNode._takeSeparator(cursor);

    final rows = <TableRowNode>[];

    while (!cursor.isEnd && cursor.peek != tableSymbol) {
      final before = cursor.position;
      final row = TableRowNode._parse(cursor);
      if (row != null) rows.add(row);
      assert(
        cursor.position > before,
        'table row parse made no progress at ${cursor.position}',
      );
    }
    if (cursor.peek == tableSymbol) cursor.take();

    // And the newline written after it, which belongs to the boundary --
    // the same as the one after a region's closing fence. See the rule in
    // `node.dart`.
    if (cursor.peek == '\n') cursor.take();

    if (rows.isEmpty) return null;
    return TableNode(align: align, children: rows);
  }

  /// What each column declared, taken from the first row that reached it.
  ///
  /// For the ordinary table -- whose first row is its widest -- that is just
  /// "the first row". A later row that is wider than every row before it
  /// declares the columns it adds.
  static List<BlockAlign?> _columns(List<TableRowNode> rows) {
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
