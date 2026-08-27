import 'package:natural_block/symbol/semantic_symbol.dart';

sealed class Node {}

sealed class LayoutNode extends Node {
  final List<Node> children;
  LayoutNode({required this.children});
}

class ColumnNode extends LayoutNode {
  ColumnNode({required super.children});
  @override
  String toString() {
    return 'ColumnNode()';
  }
}

class RowNode extends LayoutNode {
  RowNode({required super.children});
  @override
  String toString() {
    return 'RowNode()';
  }
}

sealed class ContentNode extends Node {}

class TextSpanNode extends ContentNode {
  final String text;
  final int sizeOffset;
  final SemanticSymbol style;

  TextSpanNode({
    required this.text,
    this.sizeOffset = 0,
    this.style = SemanticSymbol.none,
  });

  @override
  String toString() {
    return 'TextSpanNode(text:,sizeOffset:,style:)';
  }
}

class TextNode extends ContentNode {
  final List<TextSpanNode> children;
  TextNode({this.children = const []});

  @override
  String toString() {
    return 'TextNode()';
  }
}
