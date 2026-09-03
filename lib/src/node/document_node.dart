part of '../node.dart';

final class DocumentNode extends NaturalBlockNode {
  final List<BlockNode> children;

  DocumentNode({this.children = const []});

  static DocumentNode parse(String source) {
    final text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return DocumentNode(
      children: BlockNode._parseAll(
        _splitPieces(text, LayoutSymbol.column, allowTable: true),
      ),
    );
  }

  @override
  String toString() => 'DocumentNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
