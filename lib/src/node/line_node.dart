part of '../node.dart';

sealed class LineNode extends BlockNode {
  static LineNode _parse(String line) {
    final children = TextNode._parseInline(line);
    if (children.length == 1) {
      final only = children.single;
      if (only is VerbatimSpanNode) return VerbatimNode(text: only.text);
    }
    return TextNode(children: children);
  }
}
