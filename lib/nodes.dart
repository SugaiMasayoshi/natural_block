import 'package:natural_block/symbol/semantic_symbol.dart';

sealed class NaturalBlockNode {}

sealed class LayoutNode extends NaturalBlockNode {
  final List<NaturalBlockNode> children;
  LayoutNode({required this.children});
}

class ColumnNode extends LayoutNode {
  ColumnNode({required super.children});
  @override
  String toString() {
    return "ColumnNode(${children.map((child) => child.toString()).join(" ")})";
  }
}

class RowNode extends LayoutNode {
  RowNode({required super.children});

  @override
  String toString() {
    return "RowNode(${children.map((child) => child.toString()).join(" ")})";
  }
}

sealed class ContentNode extends NaturalBlockNode {}

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
    return "TextSpanNode(text:$text,sizeOffset:$sizeOffset,style:$style)";
  }
}

class TextNode extends ContentNode {
  final List<TextSpanNode> children;
  TextNode({this.children = const []});

  @override
  String toString() {
    return "TextNode(${children.map((child) => child.toString()).join(" ")})";
  }
}
