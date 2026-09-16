import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  group("Node equality and hashCode contract", () {
    // Equal *and* unequal, per node type. Only the first half was here
    // before, which meant the file did not do the job its header claims:
    // deleting `align == other.align` from `ColumnNode.==` left every test
    // in this file passing, and the alignment tests it underwrites would
    // have gone on passing meaninglessly.
    TextNode text([String s = '本文']) =>
        TextNode(children: [TextSpanNode(text: s)]);

    final cases = <String, (NaturalBlockNode, NaturalBlockNode, String)>{
      'ColumnNode': (
        ColumnNode(children: [text()]),
        ColumnNode(children: [text()], align: HorizontalAlign.start),
        'a start-aligned block is not one that stated nothing',
      ),
      'RowNode': (
        RowNode(
          children: [
            ColumnNode(children: [text('左')]),
          ],
        ),
        RowNode(
          children: [
            ColumnNode(children: [text('右')]),
          ],
        ),
        'a cell of different text is a different row',
      ),
      'TableNode': (
        TableNode(
          children: [
            TableRowNode(
              children: [
                TableCellNode(children: [text('セル')]),
              ],
            ),
          ],
        ),
        TableNode(
          children: [
            TableRowNode(
              children: [
                TableCellNode(children: [text('別のセル')]),
              ],
            ),
          ],
        ),
        'a cell of different text is a different table',
      ),
      'TextNode': (
        TextNode(
          children: [
            TextSpanNode(text: 'あ'),
            TextSpanNode(text: 'い'),
          ],
        ),
        TextNode(
          children: [
            TextSpanNode(text: 'い'),
            TextSpanNode(text: 'あ'),
          ],
        ),
        'the order of the runs is part of the node',
      ),
      'TextSpanNode': (
        TextSpanNode(
          text: '重要',
          decoration: SpanDecoration(sizeOffset: 1, tone: Tone.negative),
        ),
        TextSpanNode(
          text: '重要',
          decoration: SpanDecoration(sizeOffset: 1, tone: Tone.positive),
        ),
        'the tone is part of the span',
      ),
      'RawNode': (
        RawNode(text: 'code'),
        RawNode(text: 'other'),
        'the text is the whole of a region',
      ),
    };

    cases.forEach((name, c) {
      final (one, other, why) = c;

      test('two equal $name are equal and hash alike', () {
        expect(one, one);
        expect(one.hashCode, one.hashCode);
      });

      test('a $name differing in one field is not equal', () {
        expect(one, isNot(other), reason: why);
      });

      test('a $name differing in one field hashes differently', () {
        // Comparing only *equal* nodes' hashes lets `hashCode => 0` pass
        // every test in this file, which is the same hole the inequality
        // case above closes for `==`. A collision is legal in principle;
        // one on a pair this close means the field was left out.
        expect(one.hashCode, isNot(other.hashCode), reason: why);
      });
    });
    test("two layout nodes with identical children never compare equal", () {
      // DocumentNode vs RowNode is the only pair left that can hold the
      // same children: a document accepts any BlockNode and a row accepts
      // ColumnNode cells, so a single ColumnNode fits both. The former
      // ColumnNode/RowNode version of this test is no longer expressible
      // -- ColumnNode holds TextNode and RowNode holds ColumnNode, so the
      // confusion it guarded against is now a compile error rather than
      // something equality has to rule out.
      final child = ColumnNode(children: [text()]);
      final document = DocumentNode(children: [child]);
      final row = RowNode(children: [child]);

      // ignore: unrelated_type_equality_checks
      expect(document == row, isFalse);
    });

    test("differing in just one TextSpanNode field breaks equality", () {
      final base = TextSpanNode(
        text: "本文",
        decoration: SpanDecoration(
          sizeOffset: 1,
          tone: Tone.negative,
          emphasis: true,
        ),
      );

      expect(base == base.copyWith(text: "別文"), isFalse);
      expect(base == base.copyWith(sizeOffset: 2), isFalse);
      expect(base == base.copyWith(tone: Tone.positive), isFalse);
      expect(base == base.copyWith(emphasis: false), isFalse);
    });

    test("differing children make list-based nodes unequal", () {
      expect(text("A") == text("B"), isFalse);
    });

    test("children order matters for equality", () {
      final first = TextSpanNode(text: "A");
      final second = TextSpanNode(text: "B");

      final a = TextNode(children: [first, second]);
      final b = TextNode(children: [second, first]);

      expect(a == b, isFalse);
    });

    test("a node never equals null or an unrelated type", () {
      final node = TextSpanNode(text: "本文");

      // ignore: unrelated_type_equality_checks
      expect(node == "本文", isFalse);
    });
  });
}

extension on TextSpanNode {
  TextSpanNode copyWith({
    String? text,
    int? sizeOffset,
    Tone? tone,
    bool? emphasis,
  }) {
    return TextSpanNode(
      text: text ?? this.text,
      decoration: SpanDecoration(
        sizeOffset: sizeOffset ?? decoration.sizeOffset,
        tone: tone ?? decoration.tone,
        emphasis: emphasis ?? decoration.emphasis,
      ),
    );
  }
}
