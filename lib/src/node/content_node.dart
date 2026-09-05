part of '../node.dart';

/// What a [ColumnNode] is made of.
///
/// **Not a line.** This was called `LineNode` and it misled: a [TextNode]
/// runs across as many newlines as the author wrote, because a newline is a
/// character rather than a boundary. A block of three lines is one
/// `TextNode` holding two `\n`s, not three nodes.
///
/// What actually divides these is a verbatim region written on a line of its
/// own -- `text` / region / `text` -- so the pieces are runs of content
/// separated by blocks that are taken literally, and nothing else.
///
/// The tree has no line-level structure at all. That is worth stating
/// plainly, because a per-line role is exactly what a heading or a list item
/// would need, and the old name suggested somewhere to put one.
///
/// Not a [BlockNode]: content never stands directly in a document, because
/// a block always wraps it. That wrapping is unconditional, so the depth of
/// the tree does not change with whether a marker happened to be written.
sealed class ContentNode extends NaturalBlockNode {
  /// Reads whichever kind of content starts here.
  ///
  /// Null when it turned out to hold nothing.
  static ContentNode? _parse(SourceCursor cursor) {
    if (VerbatimNode._opensAt(cursor)) return VerbatimNode._parse(cursor);
    final text = TextNode._parse(cursor);
    return text.children.isEmpty ? null : text;
  }
}
