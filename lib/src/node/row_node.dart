part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  /// Continues a block that turned out to be a row, given the cell already
  /// read. Null when it was not one: a row is a block that read a `=`.
  ///
  /// Each `=` is consumed because it is the row's own; the `|` that ends the
  /// row is left for whoever arranges blocks.
  static List<ColumnNode>? _parseCells(Scanner scanner, ColumnNode first) {
    if (LayoutSymbol.byChar[scanner.peek] != LayoutSymbol.row) return null;

    final cells = [first];
    while (LayoutSymbol.byChar[scanner.peek] == LayoutSymbol.row) {
      scanner.take();
      // A separator at the very end of the source opens nothing: without
      // this, `a=b=` would gain a third cell the author never wrote, and an
      // empty cell is a position the layout keeps.
      if (scanner.isEnd) break;

      final cluster = readMarkerCluster(scanner.source, scanner.position);
      scanner.skipTo(cluster.end);
      cells.add(ColumnNode._parse(scanner, cluster.align));
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
