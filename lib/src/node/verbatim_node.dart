part of '../node.dart';

final class VerbatimNode extends ContentNode {
  final String text;

  VerbatimNode({required this.text});

  /// Whether one of these opens at the cursor.
  ///
  /// A region is a block when it was written on a line of its own, and a run
  /// inside a line otherwise -- the same fence, told apart by where it sits.
  /// Stated once and asked by both sides: the line that must not take it and
  /// the block that must. If the two disagreed, neither would consume the
  /// fence and the caller's loop would never advance.
  ///
  /// The cheap half is asked first: a fence written mid-line is never a
  /// block, and settling that costs one character rather than a search for
  /// the closing fence.
  static bool _opensAt(SourceCursor cursor) =>
      (cursor.position == 0 || cursor.peekAt(-1) == '\n') &&
      VerbatimSpanNode._opensAt(cursor);

  /// Consumes the region opening at the cursor, plus the newline written
  /// against its closing fence -- that newline belongs to the boundary.
  static VerbatimNode _parse(SourceCursor cursor) {
    final (text, end) = verbatimRegion(cursor.source, cursor.position);
    cursor.jumpTo(end);
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
