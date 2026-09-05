part of '../node.dart';

final class VerbatimSpanNode extends InlineNode {
  final String text;

  VerbatimSpanNode({required this.text});

  /// Consumes the region opening at the cursor.
  ///
  /// Null when the region held nothing: an empty pair of fences styles no
  /// text, so there is nothing to draw monospaced.
  static VerbatimSpanNode? _parse(Scanner scanner) {
    final text = scanner.takeVerbatim();
    return text.isEmpty ? null : VerbatimSpanNode(text: text);
  }

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
