import 'package:natural_block/natural_block.dart';

/// A one-line rendering of [document], for tables of expected results.
///
/// `Col[...]` and `Row[...]` are the layouts, `Table[cell / cell; ...]` a
/// table, `Raw"..."` a raw block and `raw"..."` a raw run. A text node is its
/// runs separated by spaces. Alignment is written after the node it belongs
/// to (`Col<`, `Col=`, `Col>`), and decoration after its run (`"a"{+2 neg}`).
///
/// [shapeOnly] leaves out alignment and decoration, keeping only the node
/// kinds, where runs split, and the text. [rewriteText] rewrites the text of
/// every run before it is quoted.
String show(
  DocumentNode document, {
  bool shapeOnly = false,
  String Function(String)? rewriteText,
}) {
  if (document.children.isEmpty) return '(empty)';
  final render = _Show(shapeOnly, rewriteText ?? (s) => s);
  return document.children.map(render.layout).join(', ');
}

class _Show {
  final bool shapeOnly;
  final String Function(String) rewriteText;

  _Show(this.shapeOnly, this.rewriteText);

  String layout(LayoutNode node) => switch (node) {
    ColumnNode() => column(node),
    RowNode(:final children) => 'Row[${children.map(column).join(', ')}]',
  };

  String column(ColumnNode node) =>
      'Col${align(node.align)}[${node.children.map(content).join(', ')}]';

  String content(ContentNode node) => switch (node) {
    TextNode(:final children) => children.map(inline).join(' '),
    RawNode(:final text) => 'Raw${quote(text)}',
    TableNode(:final children) =>
      'Table[${children.map((row) => row.children.map(cell).join(' / ')).join('; ')}]',
  };

  String cell(TableCellNode node) =>
      '${align(node.align)}[${node.children.map(content).join(', ')}]';

  String inline(InlineNode node) => switch (node) {
    TextSpanNode(:final text, :final decoration) =>
      '${quote(text)}${decorate(decoration)}',
    RawSpanNode(:final text) => 'raw${quote(text)}',
  };

  String quote(String s) {
    final escaped = rewriteText(s)
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n');
    return '"$escaped"';
  }

  String align(HorizontalAlign align) {
    if (shapeOnly) return '';
    return switch (align) {
      HorizontalAlign.unstated => '',
      HorizontalAlign.start => '<',
      HorizontalAlign.center => '=',
      HorizontalAlign.end => '>',
    };
  }

  String decorate(SpanDecoration d) {
    if (shapeOnly || d == const SpanDecoration()) return '';
    final parts = [
      if (d.sizeOffset > 0) '+${d.sizeOffset}',
      if (d.sizeOffset < 0) '${d.sizeOffset}',
      if (d.tone != Tone.none) d.tone.name,
      if (d.isEmphasized) '*',
      if (d.isCustom) '@',
    ];
    return '{${parts.join(' ')}}';
  }
}
