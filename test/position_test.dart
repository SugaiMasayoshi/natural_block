import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  /// Each node in [source], in order, with the text it was read from.
  List<String> spans(String source) {
    final document = NaturalBlockParser.parse(source);
    final normalized = normalizeSource(source);
    return [
      for (final node in [document, ...document.descendants])
        '${node.runtimeType} ${normalized.substring(node.start!, node.end!)}',
    ];
  }

  test('a block keeps its alignment marker and a span its cluster', () {
    expect(spans('a\n:*b:* c\n\n>d'), [
      'DocumentNode a\n:*b:* c\n\n>d',
      'ColumnNode a\n:*b:* c\n\n',
      'TextNode a\n:*b:* c\n',
      'TextSpanNode a\n',
      'TextSpanNode :*b',
      'TextSpanNode :* c\n',
      'ColumnNode >d',
      'TextNode d',
      'TextSpanNode d',
    ]);
  });

  test('a row keeps its alignment marker and a cell its own', () {
    expect(spans('<^a^>b^\nc'), [
      'DocumentNode <^a^>b^\nc',
      'RowNode <^a^>b^\n',
      'ColumnNode a',
      'TextNode a',
      'TextSpanNode a',
      'ColumnNode >b',
      'TextNode b',
      'TextSpanNode b',
      'ColumnNode c',
      'TextNode c',
      'TextSpanNode c',
    ]);
  });

  test('a table runs from its opening ~ to its closing ~', () {
    expect(spans('~^a^\nb^\n~\n`r`'), [
      'DocumentNode ~^a^\nb^\n~\n`r`',
      'ColumnNode ~^a^\nb^\n~\n`r`',
      'TableNode ~^a^\nb^\n~',
      'TableRowNode ^a^\n',
      'TableCellNode a',
      'TextNode a',
      'TextSpanNode a',
      'TableRowNode b^\n',
      'TableCellNode b',
      'TextNode b',
      'TextSpanNode b',
      'TextNode `r`',
      'RawSpanNode `r`',
    ]);
  });

  test('a raw block keeps its fences', () {
    expect(spans('```\nx\n```'), [
      'DocumentNode ```\nx\n```',
      'ColumnNode ```\nx\n```',
      'RawNode ```\nx\n```',
    ]);
  });

  test('offsets count CRLF as one character and drop the final line break', () {
    final document = NaturalBlockParser.parse('>a\r\n>b\r\n');
    final second = document.children[1];
    expect((second.start, second.end), (3, 5));
    expect((document.start, document.end), (0, 5));
  });

  test('normalizeSource writes line breaks as LF and drops the last one', () {
    expect(normalizeSource('a\r\nb\rc\n'), 'a\nb\nc');
    expect(normalizeSource('a\n\n'), 'a\n');
    expect(normalizeSource(''), '');
  });

  test('positions take no part in equality', () {
    final parsed = NaturalBlockParser.parse('a');
    final built = DocumentNode(
      children: [
        ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: 'a')]),
          ],
        ),
      ],
    );
    expect(parsed, built);
    expect(parsed.hashCode, built.hashCode);
    expect(built.start, isNull);
  });
}
