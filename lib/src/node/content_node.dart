part of '../node.dart';

/// What a block holds, and what gets arranged.
///
/// **Not a line.** This was called `LineNode` and it misled: a [TextNode]
/// runs across as many newlines as the author wrote, because a newline is a
/// character rather than a boundary. A block of three lines is one
/// `TextNode` holding two `\n`s, not three nodes.
///
/// Three kinds, and a table is one of them -- the same as a verbatim region:
/// something written between delimiters that arrives already formatted. That
/// is what lets a block hold text, a table, and more text without breaking
/// in two, so an alignment written on the block reaches all of it.
///
/// The tree has no line-level structure at all. That is worth stating
/// plainly, because a per-line role is exactly what a heading or a list item
/// would need, and the old name suggested somewhere to put one.
sealed class ContentNode extends NaturalBlockNode {
  /// Whether content other than a run of text starts at the cursor.
  ///
  /// The dispatch below, asked as a question. A [TextNode] needs the same
  /// answer to know where to stop, because it has to end wherever this
  /// would pick something else -- and asking it here rather than naming the
  /// other kinds keeps "what content can be" in one place.
  static bool _othersStartHere(SourceCursor cursor) =>
      cursor.peek == tableSymbol || VerbatimNode._opensAt(cursor);

  /// Reads whichever kind of content starts here.
  ///
  /// Null when it turned out to hold nothing.
  static ContentNode? _parse(SourceCursor cursor) {
    if (cursor.peek == tableSymbol) return TableNode._parse(cursor);
    if (VerbatimNode._opensAt(cursor)) return VerbatimNode._parse(cursor);

    final text = TextNode._parse(cursor);
    return text.children.isEmpty ? null : text;
  }
}
