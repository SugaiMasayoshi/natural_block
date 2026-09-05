part of '../node.dart';

sealed class InlineNode extends NaturalBlockNode {
  /// Reads whichever kind of inline content starts here, together with the
  /// decoration state it leaves behind.
  ///
  /// The same shape [BlockNode] and [ContentNode] have: the sealed supertype
  /// decides which of its subtypes the source becomes. This one also passes
  /// the decoration along, because a run's style is carried in from what was
  /// written before it rather than found within it.
  ///
  /// Null when the run turned out to be empty -- a cluster with no text
  /// after it changes the style and contributes no node.
  static (InlineNode?, SpanDecoration) _parse(
    SourceCursor cursor,
    SpanDecoration style,
  ) {
    if (VerbatimSpanNode._opensAt(cursor)) {
      return (VerbatimSpanNode._parse(cursor), style);
    }
    return TextSpanNode._parse(cursor, style);
  }
}
