part of '../node.dart';

final class DocumentNode extends NaturalBlockNode {
  final List<BlockNode> children;

  DocumentNode({this.children = const []});

  static DocumentNode parse(String source) {
    final scanner = Scanner(
      source.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
    );
    final children = <BlockNode>[];

    // The first block is opened by the start of the source, not by a
    // separator, so it carries no markers -- a leading `~` is text.
    var cluster = const MarkerCluster(align: null, togglesTable: false, end: 0);

    // A separator at the very end of the source needs no special case: the
    // block it opens is empty, and an empty Column block contributes no
    // node.
    while (true) {
      children.addAll(BlockNode._parse(scanner, cluster));
      if (scanner.isEnd) break;
      cluster = BlockNode._openNext(scanner);
    }

    return DocumentNode(children: children);
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
