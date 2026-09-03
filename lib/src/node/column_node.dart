part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<LineNode> children;
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  static List<LineNode> _parseLines(String block) {
    var text = block;
    if (text.startsWith('\n')) text = text.substring(1);
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    if (text.isEmpty) return const [];

    final children = <LineNode>[];
    final scanner = Scanner(text, symbols: const {}, stopAtVerbatim: true);
    final pending = StringBuffer();

    void flush() {
      final run = pending.toString();
      pending.clear();
      if (run.isEmpty) return;
      children.add(TextNode(children: TextNode._parseInline(run)));
    }

    while (true) {
      final from = scanner.position;
      final scanned = scanner.read();
      final verbatim = scanned.verbatim;

      if (verbatim == null) {
        pending.write(scanned.text);
        break;
      }

      final start = from + scanned.text.length;
      final end = scanner.position;
      final standalone =
          (start == 0 || text[start - 1] == '\n') &&
          (end == text.length || text[end] == '\n');

      if (!standalone) {
        pending.write(scanned.text);
        pending.write(text.substring(start, end));
        continue;
      }

      final before = scanned.text;
      pending.write(
        before.endsWith('\n') ? before.substring(0, before.length - 1) : before,
      );
      flush();
      children.add(VerbatimNode(text: verbatim));
      if (end < text.length) scanner.skipTo(end + 1);
    }

    flush();
    return children;
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
