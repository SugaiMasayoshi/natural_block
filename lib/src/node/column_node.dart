part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<TextNode> children;
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  static List<TextNode> _parseLines(String block) {
    final scanner = Scanner(block, symbols: const {'\n'});
    final lines = <String>[];
    while (true) {
      final scanned = scanner.read();
      lines.add(scanned.text);
      if (scanned.isEnd) break;
    }

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(TextNode._parse).toList();
  }

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

class _PendingCell {
  final List<TextNode> lines;
  final BlockAlign? statedAlign;

  const _PendingCell({required this.lines, required this.statedAlign});

  ColumnNode resolve(BlockAlign inherited) =>
      ColumnNode(children: lines, align: statedAlign ?? inherited);
}
