part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  static RowNode _fromCells(List<_PendingCell> cells) => RowNode(
    children: [for (final cell in cells) cell.resolve(BlockAlign.start)],
  );

  @override
  String toString() => 'RowNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode => Object.hash(runtimeType, _childrenEquality.hash(children));
}
