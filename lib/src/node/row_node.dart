part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  static RowNode _of(List<_Cell> cells) =>
      RowNode(children: [for (final c in cells) c.resolve(BlockAlign.start)]);

  /// Continues a block that turned out to be a row, given the cell already
  /// read. Null when it was not one: a row is a block that read a `=`.
  ///
  /// Each `=` is consumed because it is the row's own; the `|` that ends the
  /// row is left for whoever arranges blocks.
  static List<_Cell>? _parseCells(Scanner scanner, _Cell first) {
    if (LayoutSymbol.byChar[scanner.peek] != LayoutSymbol.row) return null;

    final cells = [first];
    while (LayoutSymbol.byChar[scanner.peek] == LayoutSymbol.row) {
      scanner.take();
      // A separator at the very end of the source opens nothing: without
      // this, `a=b=` would gain a third cell the author never wrote, and an
      // empty cell is a position the layout keeps.
      if (scanner.isEnd) break;

      final cluster = readMarkerCluster(
        scanner.source,
        scanner.position,
        allowTable: false,
      );
      scanner.skipTo(cluster.end);
      cells.add(
        _Cell(ColumnNode._parse(scanner, cluster.align), cluster.align),
      );
    }
    return cells;
  }

  @override
  String toString() => 'RowNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// A cell, plus whether its alignment was stated rather than defaulted.
///
/// Null is not the same as [BlockAlign.start]: inside a table only a cell
/// that said nothing inherits its column's alignment.
class _Cell {
  final ColumnNode node;
  final BlockAlign? statedAlign;

  const _Cell(this.node, this.statedAlign);

  ColumnNode resolve(BlockAlign inherited) =>
      ColumnNode(children: node.children, align: statedAlign ?? inherited);
}
