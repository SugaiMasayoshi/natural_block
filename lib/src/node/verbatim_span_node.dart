part of '../node.dart';

final class VerbatimSpanNode extends InlineNode {
  final String text;

  VerbatimSpanNode({required this.text});

  @override
  String toString() => 'VerbatimSpanNode(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerbatimSpanNode && text == other.text;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}
