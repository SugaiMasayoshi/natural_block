part of '../node.dart';

final class TableNode extends BlockNode {
  final List<RowNode> children;
  final BlockAlign align;

  TableNode({this.children = const [], this.align = BlockAlign.start});

  /// Reads the run of rows this table owns, and closes itself.
  ///
  /// Nothing above knows a table is open: the `~` that closes one is read
  /// here, and the first thing that cannot join is handed back as a sibling
  /// rather than pushed back onto the cursor.
  static _Parsed<List<BlockNode>> _parse(Scanner scanner, BlockAlign align) {
    final rows = <RowNode>[];
    final after = <BlockNode>[];
    List<BlockAlign>? columnAligns;
    var cluster = const MarkerCluster(align: null, togglesTable: false, end: 0);
    String? terminator;

    while (true) {
      final row = RowNode._parseCells(scanner, cluster.align);
      final cells = row.node.cells;
      terminator = row.terminator;

      final fits =
          row.node.isRow &&
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
        final blocks = BlockNode._blocksFrom(row.node, cluster.align);
        // An empty block contributes nothing, so it cannot end a table --
        // otherwise `||` would be an invisible separator splitting one in
        // two on something the AST does not record.
        if (blocks.isNotEmpty) {
          after.addAll(blocks);
          break;
        }
      }

      if (terminator == null) break;
      cluster = BlockNode._readCluster(scanner);
      if (cluster.togglesTable) {
        // Closing. The alignment in this cluster belongs to the block being
        // opened after the table, not to the table that just ended, so the
        // block is read here rather than handed back unmarked.
        if (scanner.isEnd) break;
        final next = RowNode._parseCells(scanner, cluster.align);
        after.addAll(BlockNode._blocksFrom(next.node, cluster.align));
        terminator = next.terminator;
        break;
      }
    }

    return _Parsed([
      if (rows.isNotEmpty) TableNode(children: rows, align: align),
      ...after,
    ], terminator);
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
