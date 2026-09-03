part of '../node.dart';

final class TableNode extends BlockNode {
  final List<RowNode> children;

  final BlockAlign align;

  TableNode({this.children = const [], this.align = BlockAlign.start});

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
