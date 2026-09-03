part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<TextNode> children;

  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  @override
  String toString() => 'ColumnNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}
