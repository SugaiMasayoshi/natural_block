part of '../node.dart';

final class TextSpanNode extends InlineNode {
  final String text;

  final int sizeOffset;

  final SemanticColor color;

  final bool emphasis;

  final bool isAction;

  TextSpanNode({
    required this.text,
    this.sizeOffset = 0,
    this.color = SemanticColor.none,
    this.emphasis = false,
    this.isAction = false,
  });

  @override
  String toString() {
    return 'TextSpanNode(text: $text, sizeOffset: $sizeOffset, '
        'color: $color, emphasis: $emphasis, isAction: $isAction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSpanNode &&
        text == other.text &&
        sizeOffset == other.sizeOffset &&
        color == other.color &&
        emphasis == other.emphasis &&
        isAction == other.isAction;
  }

  @override
  int get hashCode => Object.hash(text, sizeOffset, color, emphasis, isAction);
}
