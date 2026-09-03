part of '../node.dart';


/// The root of a parsed document: exactly one per `NaturalBlockParser.parse`
/// call, holding the blocks that make up the document.
///
/// Deliberately *not* a `ColumnNode`, even though both stack their children
/// vertically. The two differ in what they can contain -- a document holds
/// any [BlockNode], while a column holds only lines -- and a document has no
/// alignment of its own, having nothing to be aligned within. Sharing one
/// type for both meant a single `children` list that had to admit every node
/// kind, and an `align` field on the root that was never anything but its
/// default.
final class DocumentNode extends NaturalBlockNode {
  /// The blocks making up the document, in the order they were written.
  final List<BlockNode> children;

  /// Creates a document holding [children].
  DocumentNode({this.children = const []});

  @override
  String toString() => 'DocumentNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode => Object.hash(runtimeType, _childrenEquality.hash(children));
}
