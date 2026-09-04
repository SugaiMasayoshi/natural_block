part of '../node.dart';

sealed class BlockNode extends NaturalBlockNode {
  /// Reads whichever block starts here, given the marker cluster that opened
  /// it. Stops in front of the `|` or `~` that ends it, which belongs to
  /// whatever arranges the blocks.
  ///
  /// The first cell is read before anything is known about what the block
  /// is, because the same text serves either reading. What the separator
  /// after it turns out to be decides who finishes the job, and the cell
  /// already read is handed on rather than re-read or re-labelled.
  static List<BlockNode> _parse(Scanner scanner, MarkerCluster cluster) {
    final first = ColumnNode._parse(scanner, cluster.align);
    final row = RowNode._parse(scanner, first);
    if (row != null) return [row];

    // An empty Column block is content that is not there, so it contributes
    // no node -- `左||右` is two blocks, not three.
    return first.children.isEmpty ? const [] : [first];
  }

  /// Consumes the layout symbol the cursor is on and reads the markers
  /// written after it -- they belong to the block that symbol opens.
  static MarkerCluster _openNext(Scanner scanner) {
    scanner.take();
    final cluster = readMarkerCluster(scanner.source, scanner.position);
    scanner.skipTo(cluster.end);
    return cluster;
  }
}
