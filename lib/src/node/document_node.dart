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

    while (true) {
      final block = BlockNode._parse(scanner, cluster);
      children.addAll(block.node);
      if (block.terminator == null) break;
      if (scanner.isEnd) break;
      cluster = BlockNode._readCluster(scanner);
      if (scanner.isEnd && !cluster.togglesTable) break;
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
