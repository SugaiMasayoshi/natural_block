import 'package:natural_block/parser.dart';
import 'package:test/test.dart';

void main() {
  final parser = NaturalBlockParser();

  group("Column Newline Trim", () {
    const expected = "ColumnNode(ColumnNode(TextNode(TestText)))";

    const cases = [
      "|TestText|",
      "|\nTestText|",
      "|TestText\n|",
      "|\nTestText\n|",
      "\n|TestText|",
      "|TestText|\n",
      "\n|TestText|\n",
    ];

    for (final (id, input) in cases.indexed) {
      test("Column Newline trim : $id", () {
        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    }
  });

  group("Row Newline Trim", () {
    const expected =
        "ColumnNode(ColumnNode(RowNode(TextNode(TestTextA) TextNode(TestTextB))))";

    const cases = [
      "||TestTextA=TestTextB||",
      "||\nTestTextA=TestTextB||",
      "||TestTextA=TestTextB\n||",
      "||\nTestTextA=TestTextB\n||",
      "|\n|TestTextA=TestTextB||",
      "||TestTextA=TestTextB|\n|",
      "|\n|TestTextA=TestTextB|\n|",
    ];

    for (final (id, input) in cases.indexed) {
      test("Row Newline trim : $id", () {
        final nodes = parser.parse(input);
        expect(nodes.toString(), expected);
      });
    }
  });
}
