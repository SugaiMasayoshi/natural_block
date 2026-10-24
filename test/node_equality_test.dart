import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  TextNode text([String s = 'a']) =>
      TextNode(children: [TextSpanNode(text: s)]);

  final cases = <String, (NaturalBlockNode Function(), List<NaturalBlockNode>)>{
    'DocumentNode': (
      () => DocumentNode(
        children: [
          ColumnNode(children: [text()]),
        ],
      ),
      [
        DocumentNode(
          children: [
            ColumnNode(children: [text('b')]),
          ],
        ),
      ],
    ),
    'ColumnNode': (
      () => ColumnNode(children: [text()]),
      [
        ColumnNode(children: [text('b')]),
        ColumnNode(children: [text()], align: HorizontalAlign.start),
      ],
    ),
    'RowNode': (
      () => RowNode(
        children: [
          ColumnNode(children: [text()]),
          ColumnNode(children: [text()]),
        ],
      ),
      [
        RowNode(
          children: [
            ColumnNode(children: [text()]),
            ColumnNode(children: [text('b')]),
          ],
        ),
      ],
    ),
    'TableNode': (
      () => TableNode(
        children: [
          TableRowNode(
            children: [
              TableCellNode(children: [text()]),
            ],
          ),
        ],
      ),
      [
        TableNode(
          children: [
            TableRowNode(
              children: [
                TableCellNode(children: [text('b')]),
              ],
            ),
          ],
        ),
      ],
    ),
    'TableRowNode': (
      () => TableRowNode(
        children: [
          TableCellNode(children: [text()]),
        ],
      ),
      [
        TableRowNode(
          children: [
            TableCellNode(children: [text('b')]),
          ],
        ),
      ],
    ),
    'TableCellNode': (
      () => TableCellNode(children: [text()]),
      [
        TableCellNode(children: [text('b')]),
        TableCellNode(children: [text()], align: HorizontalAlign.start),
      ],
    ),
    'TextNode': (
      () => TextNode(
        children: [
          TextSpanNode(text: 'a'),
          TextSpanNode(text: 'b'),
        ],
      ),
      [
        TextNode(
          children: [
            TextSpanNode(text: 'b'),
            TextSpanNode(text: 'a'),
          ],
        ),
      ],
    ),
    'TextSpanNode': (
      () => TextSpanNode(text: 'a'),
      [
        TextSpanNode(text: 'b'),
        TextSpanNode(text: 'a', decoration: SpanDecoration(isEmphasized: true)),
      ],
    ),
    'RawNode': (() => RawNode(text: 'a'), [RawNode(text: 'b')]),
    'RawSpanNode': (() => RawSpanNode(text: 'a'), [RawSpanNode(text: 'b')]),
  };

  cases.forEach((name, c) {
    final (make, others) = c;

    test('$name built twice is equal and hashes alike', () {
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('$name differing in one field is unequal and hashes apart', () {
      for (final other in others) {
        expect(other, isNot(make()));
        expect(other.hashCode, isNot(make().hashCode));
      }
    });
  });

  test('every SpanDecoration field takes part in equality', () {
    const plain = SpanDecoration();
    const others = [
      SpanDecoration(sizeOffset: 1),
      SpanDecoration(tone: Tone.negative),
      SpanDecoration(isEmphasized: true),
      SpanDecoration(isCustom: true),
    ];
    for (final other in others) {
      expect(other, isNot(plain));
      expect(other.hashCode, isNot(plain.hashCode));
    }
  });

  test('node types with the same fields never compare equal', () {
    final column = ColumnNode(children: [text()]);

    expect(
      RowNode(children: [column, column]),
      isNot(DocumentNode(children: [column, column])),
    );
    expect(RawSpanNode(text: 'a'), isNot(RawNode(text: 'a')));
  });
}
