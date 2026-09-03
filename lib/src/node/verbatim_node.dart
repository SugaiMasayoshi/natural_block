part of '../node.dart';


/// Text taken exactly as written, between a pair of `` ` `` fences.
///
/// The one place the language stops reading. Nothing inside is a separator,
/// a decoration, or an escape -- which is what makes it possible to write
/// code at all. Measured before this existed:
/// `final x = a == b ? 1 : 2;` became a four-cell row, and
/// `cat file.txt | grep foo` became three blocks. `=` and `|` are the
/// characters code uses most, so the language's promise that ordinary prose
/// survives untouched runs backwards for code, and escaping every one of
/// them by hand was the only way out.
///
/// An inline node rather than a block one, even though a region often stands
/// alone as a code block. Whether it *looks* like a block is about where it
/// was written, not about what it is, so that decision belongs to whatever
/// renders it -- a region that is a line's only child is the whole line, and
/// can be drawn as a block; one sitting among text is a run inside it.
///
/// Holds a plain [String]: a run that is never decorated has nothing to
/// split into spans, and no color, emphasis or size could mean anything
/// here.
final class VerbatimNode extends InlineNode {
  /// The content, exactly as written, apart from one thing the source
  /// cannot express otherwise: the newline directly against each fence is
  /// treated as part of that fence, so a fence can sit on its own line.
  /// CRLF is normalized to LF before parsing, so line endings do not
  /// round-trip.
  final String text;

  /// Creates a verbatim region holding [text].
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
