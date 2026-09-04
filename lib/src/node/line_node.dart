part of '../node.dart';

/// Something that stacks inside a [ColumnNode].
///
/// Not a [BlockNode]: a line never stands directly in a document, because a
/// block always wraps it. That wrapping is unconditional, so the depth of
/// the tree does not change with whether a marker happened to be written.
sealed class LineNode extends NaturalBlockNode {
  /// Reads whichever kind of line starts here.
  ///
  /// Null when the line turned out to have no content.
  static LineNode? _parse(Scanner scanner) {
    if (scanner.atBlockRegion) return VerbatimNode._parse(scanner);
    final line = TextNode._parse(scanner);
    return line.children.isEmpty ? null : line;
  }
}
