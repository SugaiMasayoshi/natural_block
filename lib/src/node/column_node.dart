part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<LineNode> children;
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  /// Reads one cell or block: everything up to the next `|` or `=`, which it
  /// leaves for whoever those belong to -- `=` divides cells and is the
  /// row's, `|` divides blocks and is the document's or the table's.
  ///
  /// Decides only what kind of child comes next, by looking at the cursor.
  /// Each child reads itself and stops before anything that is not its own.
  static ColumnNode _parse(Scanner scanner, BlockAlign? align) {
    // The newline written against the separator that opened this block
    // belongs to that separator, which is what lets `|` sit on a line of
    // its own without opening a blank one.
    if (scanner.peek == '\n') scanner.take();

    final lines = <LineNode>[];

    while (!scanner.isEnd && !LayoutSymbol.byChar.containsKey(scanner.peek)) {
      final before = scanner.position;
      final line = LineNode._parse(scanner);
      if (line != null) lines.add(line);
      assert(
        scanner.position > before,
        'line parse made no progress at ${scanner.position}',
      );
    }

    return ColumnNode(children: lines, align: align ?? BlockAlign.start);
  }

  @override
  String toString() => 'ColumnNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}
