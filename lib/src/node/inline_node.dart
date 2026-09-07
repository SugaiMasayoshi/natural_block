part of '../node.dart';

sealed class InlineNode extends NaturalBlockNode {
  /// Reads whichever kind of inline content starts here, together with the
  /// decoration state it leaves behind.
  ///
  /// The same shape [LayoutNode] and [ContentNode] have: the sealed supertype
  /// decides which of its subtypes the source becomes. This one also passes
  /// the decoration along, because a run's style is carried in from what was
  /// written before it rather than found within it.
  ///
  /// Null when the run turned out to be empty -- a cluster with no text
  /// after it changes the style and contributes no node.
  /// Whether inline content other than a run of styled text starts at the
  /// cursor.
  ///
  /// The dispatch below, asked as a question -- see [ContentNode] for why a
  /// run asks its own supertype rather than naming its siblings.
  static bool _othersStartHere(SourceCursor cursor) =>
      VerbatimSpanNode._opensAt(cursor);

  static (InlineNode?, SpanDecoration) _parse(
    SourceCursor cursor,
    SpanDecoration style,
  ) {
    if (_othersStartHere(cursor)) {
      return (VerbatimSpanNode._parse(cursor), style);
    }
    return TextSpanNode._parse(cursor, style);
  }
}
