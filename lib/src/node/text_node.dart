part of '../node.dart';


/// A single line, broken into one or more children wherever its content
/// changes kind or decoration partway through.
final class TextNode extends BlockNode {
  /// The pieces making up this line, left to right. A line is split into
  /// more than one wherever its decoration changes, or wherever a verbatim
  /// region starts or ends.
  final List<InlineNode> children;

  /// Creates a line made of [children] runs.
  TextNode({this.children = const []});

  @override
  String toString() => 'TextNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode => Object.hash(runtimeType, _childrenEquality.hash(children));
}
