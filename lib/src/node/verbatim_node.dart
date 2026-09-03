part of '../node.dart';

final class VerbatimNode extends InlineNode {
  final String text;

  VerbatimNode({required this.text});

  @override
  String toString() => 'VerbatimNode(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerbatimNode && text == other.text;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}
