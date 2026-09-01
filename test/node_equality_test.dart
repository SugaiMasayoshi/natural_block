import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  group("Node equality and hashCode contract", () {
    test("equal TableNodes have equal hashCode, and align is part of it", () {
      TableNode table({BlockAlign align = BlockAlign.start}) => TableNode(
        align: align,
        children: [
          RowNode(
            children: [
              ColumnNode(
                children: [
                  TextNode(children: [TextSpanNode(text: "セル")]),
                ],
              ),
            ],
          ),
        ],
      );

      expect(table(), table());
      expect(table().hashCode, table().hashCode);
      expect(
        table(),
        isNot(table(align: BlockAlign.center)),
        reason: 'a centered table is not the same node as a start-aligned one',
      );
    });

    test("equal ColumnNodes have equal hashCode", () {
      final a = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "本文")]),
        ],
      );
      final b = DocumentNode(
        children: [
          TextNode(children: [TextSpanNode(text: "本文")]),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test("equal RowNodes have equal hashCode", () {
      final a = RowNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: "左")]),
            ],
          ),
        ],
      );
      final b = RowNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: "左")]),
            ],
          ),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test("equal TextNodes have equal hashCode", () {
      final a = TextNode(
        children: [TextSpanNode(text: "危険", color: SemanticColor.danger)],
      );
      final b = TextNode(
        children: [TextSpanNode(text: "危険", color: SemanticColor.danger)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test("equal TextSpanNodes (all four fields) have equal hashCode", () {
      final a = TextSpanNode(
        text: "重要",
        sizeOffset: 1,
        color: SemanticColor.danger,
        emphasis: true,
      );
      final b = TextSpanNode(
        text: "重要",
        sizeOffset: 1,
        color: SemanticColor.danger,
        emphasis: true,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test(
      "two layout nodes with identical children never compare equal",
      () {
        // DocumentNode vs RowNode is the only pair left that can hold the
        // same children: a document accepts any BlockNode and a row accepts
        // ColumnNode cells, so a single ColumnNode fits both. The former
        // ColumnNode/RowNode version of this test is no longer expressible
        // -- ColumnNode holds TextNode and RowNode holds ColumnNode, so the
        // confusion it guarded against is now a compile error rather than
        // something equality has to rule out.
        final child = ColumnNode(
          children: [
            TextNode(children: [TextSpanNode(text: "本文")]),
          ],
        );
        final document = DocumentNode(children: [child]);
        final row = RowNode(children: [child]);

        // ignore: unrelated_type_equality_checks
        expect(document == row, isFalse);
      },
    );

    test("differing in just one TextSpanNode field breaks equality", () {
      final base = TextSpanNode(
        text: "本文",
        sizeOffset: 1,
        color: SemanticColor.danger,
        emphasis: true,
      );

      expect(base == base.copyWith(text: "別文"), isFalse);
      expect(base == base.copyWith(sizeOffset: 2), isFalse);
      expect(base == base.copyWith(color: SemanticColor.success), isFalse);
      expect(base == base.copyWith(emphasis: false), isFalse);
    });

    test("differing children make list-based nodes unequal", () {
      final a = TextNode(children: [TextSpanNode(text: "A")]);
      final b = TextNode(children: [TextSpanNode(text: "B")]);

      expect(a == b, isFalse);
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
    SemanticColor? color,
    bool? emphasis,
  }) {
    return TextSpanNode(
      text: text ?? this.text,
      sizeOffset: sizeOffset ?? this.sizeOffset,
      color: color ?? this.color,
      emphasis: emphasis ?? this.emphasis,
    );
  }
}
