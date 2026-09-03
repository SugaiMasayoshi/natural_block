part of '../node.dart';

sealed class BlockNode extends NaturalBlockNode {
  static _Parsed<List<BlockNode>> _parse(
    Scanner scanner,
    MarkerCluster cluster,
  ) {
    if (cluster.togglesTable) {
      return TableNode._parse(scanner, cluster.align ?? BlockAlign.start);
    }

    final row = RowNode._parseCells(scanner, cluster.align);
    return _Parsed(_blocksFrom(row.node, cluster.align), row.terminator);
  }

  /// What a run of cells contributes.
  ///
  /// A run that read a `=` is a row. One that did not was never a row at
  /// all: an empty block contributes nothing (a Column block is content), a
  /// marked one is a block of its own, and a bare one hands its lines up.
  static List<BlockNode> _blocksFrom(_CellRun run, BlockAlign? align) {
    if (run.isRow) {
      return [
        RowNode(
          children: [for (final c in run.cells) c.resolve(BlockAlign.start)],
        ),
      ];
    }
    final only = run.cells.single.node;
    if (only.children.isEmpty) return const [];
    if (align != null) return [only];
    return only.children;
  }

  static MarkerCluster _readCluster(Scanner scanner) {
    final cluster = readMarkerCluster(
      scanner.source,
      scanner.position,
      allowTable: true,
    );
    scanner.skipTo(cluster.end);
    return cluster;
  }
}
