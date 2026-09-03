part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  /// Reads the cells joined by `=`, stopping at the `|` that ends the row
  /// or at the end of the source.
  ///
  /// A row is discovered rather than declared: one cell means this was never
  /// a row, and the caller unwraps it.
  static _Parsed<_CellRun> _parseCells(
    Scanner scanner,
    BlockAlign? firstAlign,
  ) {
    final cells = <_Cell>[];
    var align = firstAlign;
    var sawRow = false;

    while (true) {
      final cell = ColumnNode._parse(scanner, align);
      cells.add(_Cell(cell.node, align));

      if (LayoutSymbol.byChar[cell.terminator] != LayoutSymbol.row) {
        // A separator at the very end of the source opens nothing: without
        // this, `a=b=` would gain a third cell the author never wrote, and
        // an empty cell is a position the layout keeps.
        if (cell.terminator == null &&
            cells.length > 1 &&
            cells.last.node.children.isEmpty &&
            cells.last.statedAlign == null) {
          cells.removeLast();
        }
        return _Parsed(_CellRun(cells, sawRow), cell.terminator);
      }

      sawRow = true;
      final cluster = readMarkerCluster(
        scanner.source,
        scanner.position,
        allowTable: false,
      );
      scanner.skipTo(cluster.end);
      align = cluster.align;
    }
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

/// The cells of one block, and whether a `=` was ever read.
///
/// A row is a block that contained a separator, not a block that ended up
/// with more than one cell -- `a=` drops its empty trailing cell and is
/// still a row.
class _CellRun {
  final List<_Cell> cells;
  final bool isRow;

  const _CellRun(this.cells, this.isRow);
}
