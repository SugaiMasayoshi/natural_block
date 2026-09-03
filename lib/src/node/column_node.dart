part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<LineNode> children;
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  /// Reads one cell or block: everything up to the next `|` or `=`.
  static _Parsed<ColumnNode> _parse(Scanner scanner, BlockAlign? align) {
    // The newline directly against a boundary belongs to that boundary --
    // the same rule a verbatim fence already has, applied to the separators
    // and to the edges of the source. It is what lets `|` and `|~` be
    // written on lines of their own without opening a blank one.
    if (scanner.peek == '\n') scanner.take();

    final origin = scanner.position;
    final lines = <LineNode>[];
    final pending = StringBuffer();
    String? terminator;

    void flush() {
      final run = pending.toString();
      pending.clear();
      if (run.isEmpty) return;
      lines.add(TextNode(children: TextNode._parseInline(run)));
    }

    while (true) {
      final from = scanner.position;
      final scanned = scanner.read(
        LayoutSymbol.byChar.keys.toSet(),
        stopAtVerbatim: true,
      );
      final verbatim = scanned.verbatim;

      if (verbatim == null) {
        // The other half of the boundary rule: the newline written against
        // the separator that ends this block belongs to it.
        final tail = scanned.text;
        pending.write(
          tail.endsWith('\n') ? tail.substring(0, tail.length - 1) : tail,
        );
        terminator = scanned.symbol;
        break;
      }

      final start = from + scanned.text.length;
      final end = scanner.position;
      // Alone on its line, judged within this block: the cell's own start
      // counts as a boundary, and so does the separator that ends it.
      final next = scanner.at(end);
      final standalone =
          (start == origin || scanner.at(start - 1) == '\n') &&
          (next == '' || next == '\n' || LayoutSymbol.byChar.containsKey(next));

      if (!standalone) {
        pending.write(scanned.text);
        pending.write(scanner.source.substring(start, end));
        continue;
      }

      final before = scanned.text;
      pending.write(
        before.endsWith('\n') ? before.substring(0, before.length - 1) : before,
      );
      flush();
      lines.add(VerbatimNode(text: verbatim));
      if (!scanner.isEnd && scanner.at(end) == '\n') scanner.skipTo(end + 1);
    }

    flush();
    return _Parsed(
      ColumnNode(children: lines, align: align ?? BlockAlign.start),
      terminator,
    );
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

/// A node together with the symbol that ended it, or null at the source's end.
class _Parsed<T> {
  final T node;
  final String? terminator;

  const _Parsed(this.node, this.terminator);
}
