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

class TextNode extends ContentNode {
  final String text;
  final int size;
  final List<TextNode> children;
  TextNode({required this.text, this.size = 0, this.children = const []});

  @override
  String toString() {
    return "TextNode($text)";
  }
}
