part of '../node.dart';

sealed class BlockNode extends NaturalBlockNode {
  /// Reads whichever block starts here, given the marker cluster that opened
  /// it. Stops in front of the `|` that ends it, which belongs to whatever
  /// arranges the blocks.
  static List<BlockNode> _parse(Scanner scanner, MarkerCluster cluster) {
    if (cluster.togglesTable) {
      return TableNode._parse(scanner, cluster.align ?? BlockAlign.start);
    }
    return _blocksFrom(
      RowNode._parseCells(scanner, cluster.align),
      cluster.align,
    );
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

  /// Consumes the `|` the cursor is on and reads the markers written after
  /// it -- they belong to the block that separator opens.
  static MarkerCluster _openNext(Scanner scanner) {
    scanner.take();
    final cluster = readMarkerCluster(
      scanner.source,
      scanner.position,
      allowTable: true,
    );
    scanner.skipTo(cluster.end);
    return cluster;
  }
}
