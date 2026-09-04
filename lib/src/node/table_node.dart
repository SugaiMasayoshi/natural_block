part of '../node.dart';

final class TableNode extends BlockNode {
  final List<RowNode> children;
  final BlockAlign align;

  TableNode({this.children = const [], this.align = BlockAlign.start});

  /// Reads the run of rows this table owns, and closes itself.
  ///
  /// Nothing above knows a table is open: the `~` that closes one is read
  /// here, and the first thing that cannot join is handed back as a sibling
  /// rather than pushed onto the cursor.
  static List<BlockNode> _parse(Scanner scanner, BlockAlign align) {
    final rows = <RowNode>[];
    final after = <BlockNode>[];
    List<BlockAlign>? columnAligns;
    var cluster = const MarkerCluster(align: null, togglesTable: false, end: 0);

    while (true) {
      final first = _Cell(
        ColumnNode._parse(scanner, cluster.align),
        cluster.align,
      );
      final cells = RowNode._parseCells(scanner, first);

      final fits =
          cells != null &&
          (columnAligns == null || cells.length == columnAligns.length);

      if (fits) {
        final aligns = columnAligns ??= [
          for (final cell in cells) cell.statedAlign ?? BlockAlign.start,
        ];
        rows.add(
          RowNode(
            children: [
              for (var i = 0; i < cells.length; i++)
                cells[i].resolve(aligns[i]),
            ],
          ),
        );
      } else {
        // An empty block contributes nothing, so it cannot end a table --
        // otherwise `||` would be an invisible separator splitting one in
        // two on something the AST does not record.
        final block = cells == null ? first.node : RowNode._of(cells);
        if (block is! ColumnNode || block.children.isNotEmpty) {
          after.add(block);
          break;
        }
      }

      if (scanner.isEnd) break;
      cluster = BlockNode._openNext(scanner);
      if (cluster.togglesTable) {
        // Closing. The alignment in this cluster belongs to the block being
        // opened after the table, not to the table that just ended -- but
        // the `~` itself is spent on closing, so the block is read without
        // it. Passing the cluster on unchanged would open a second table.
        if (scanner.isEnd) break;
        after.addAll(
          BlockNode._parse(
            scanner,
            MarkerCluster(
              align: cluster.align,
              togglesTable: false,
              end: cluster.end,
            ),
          ),
        );
        break;
      }
    }

    return [
      if (rows.isNotEmpty) TableNode(children: rows, align: align),
      ...after,
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
