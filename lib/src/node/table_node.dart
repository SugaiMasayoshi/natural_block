part of '../node.dart';

final class TableNode extends BlockNode {
  final List<RowNode> children;

  /// The alignment written for the table itself, or null when none was.
  final BlockAlign? align;

  TableNode({this.children = const [], this.align});

  /// Reads the run of rows between the `~` that opened the table and the one
  /// that ends it, which it stops in front of rather than consuming.
  ///
  /// Everything in between is the table's, so there is nothing to hand back:
  /// a row of a different width is padded rather than thrown out. Null when
  /// no row had any content.
  static TableNode? _parse(Scanner scanner, BlockAlign? align) {
    final rows = <List<ColumnNode>>[];

    // The alignment that opened the table describes the table, not its
    // first cell, so the first row starts with nothing stated.
    var cluster = const MarkerCluster(align: null, end: 0);

    while (true) {
      final first = ColumnNode._parse(scanner, cluster.align);
      final cells = RowNode._parseCells(scanner, first) ?? [first];

      // A block with nothing in it contributes nothing, here as anywhere,
      // which is what lets every row be written with a leading `|`.
      if (cells.length > 1 || cells.single.children.isNotEmpty) {
        rows.add(cells);
      }

      if (scanner.isEnd) break;
      if (LayoutSymbol.byChar[scanner.peek] == LayoutSymbol.table) break;
      cluster = BlockNode._openNext(scanner);
    }

    if (rows.isEmpty) return null;
    return TableNode(align: align, children: _grid(rows));
  }

  /// Squares the rows off into a grid, resolving each cell's alignment
  /// against its column.
  ///
  /// A table is a grid, so a short row is padded rather than left ragged --
  /// the renderer gives each cell an equal share of its own row's width, so
  /// a ragged row would put its cells out of line with every other row.
  ///
  /// A column's alignment is stated by the first row that has that column,
  /// which for a table whose first row is its widest is just "the first
  /// row". A cell that said nothing takes what its column said, which may
  /// itself be nothing.
  static List<RowNode> _grid(List<List<ColumnNode>> rows) {
    final columns = <BlockAlign?>[];
    for (final row in rows) {
      for (var i = columns.length; i < row.length; i++) {
        columns.add(row[i].align);
      }
    }

    return [
      for (final row in rows)
        RowNode(
          children: [
            for (var i = 0; i < columns.length; i++)
              ColumnNode(
                children: i < row.length ? row[i].children : const [],
                align: (i < row.length ? row[i].align : null) ?? columns[i],
              ),
          ],
        ),
    ];
  }

  @override
  String toString() => 'TableNode(children: $children, align: $align)';

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
