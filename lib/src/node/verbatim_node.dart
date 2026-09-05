part of '../node.dart';

final class VerbatimNode extends ContentNode {
  final String text;

  VerbatimNode({required this.text});

  /// Consumes the region opening at the cursor, plus the newline written
  /// against its closing fence -- that newline belongs to the boundary.
  static VerbatimNode _parse(SourceCursor cursor) {
    final text = cursor.takeVerbatim();
    if (cursor.peek == '\n') cursor.take();
    return VerbatimNode(text: text);
  }

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
