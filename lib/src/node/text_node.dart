part of '../node.dart';

final class TextNode extends ContentNode {
  final List<InlineNode> children;

  TextNode({this.children = const []});

  /// Whether a run of inline content ends at the cursor: the block's own
  /// separator, a verbatim region written on a line of its own, or the end
  /// of the source.
  ///
  /// One answer to one question, asked from two places for the same
  /// position: this node's loop stops here, and the last run it read has to
  /// know that the newline it just took sits against a boundary rather than
  /// inside its text. Assembled separately in both, the two could disagree
  /// and a newline would be kept in one place and dropped in the other.
  static bool _endsHere(SourceCursor cursor) =>
      cursor.isEnd ||
      layoutSymbols.contains(cursor.peek) ||
      VerbatimNode._opensAt(cursor);

  /// Reads one run of inline content, stopping in front of anything that is
  /// not its own: a separator that belongs to the block, or a verbatim
  /// region written on a line of its own.
  ///
  /// Neither is consumed. A node never eats what belongs to something else,
  /// so the caller can look at the cursor and decide what comes next.
  static TextNode _parse(SourceCursor cursor) {
    final children = <InlineNode>[];
    var style = const SpanDecoration();

    while (!_endsHere(cursor)) {
      final before = cursor.position;
      final (node, next) = InlineNode._parse(cursor, style);
      style = next;
      if (node != null) children.add(node);
      // A child that reads nothing where the loop expects content would spin
      // here forever. The mistake is silent otherwise -- it hangs rather
      // than producing a wrong tree -- so it is worth saying out loud.
      assert(
        cursor.position > before,
        'inline parse made no progress at ${cursor.position}',
      );
    }

    return TextNode(children: children);
  }

  @override
  String toString() => 'TextNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
