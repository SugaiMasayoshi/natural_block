// 【解説】 テストがどこでも使う木の組み立てとほどきを1箇所に置いたもの。
// 【解説】 番号は持ちません。ここには主張が1つも無く、他の21本が主張を
// 【解説】 書くための語彙だけがあるからです。
// 【解説】
// 【解説】 同じ line() と block() が4つのファイルに手で書かれていて、
// 【解説】 しかも escape_test.dart のものは最後の group の中にあったので、
// 【解説】 27本のうち5本しか使えませんでした。

import 'package:natural_block/natural_block.dart';

/// One line of text, the shape most cells and paragraphs take.
TextNode line(String text) => TextNode(children: [TextSpanNode(text: text)]);

/// A single-line block, which is what a bare paragraph parses to.
ColumnNode block(String text) => ColumnNode(children: [line(text)]);

/// A single-line cell, optionally stating its own alignment.
ColumnNode cell(String text, [BlockAlign? align]) =>
    ColumnNode(children: [line(text)], align: align);

/// An empty cell -- what an explicit `^^` holds, and what a short row is
/// padded with when it is drawn.
ColumnNode empty([BlockAlign? align]) => ColumnNode(align: align);

/// The document's only block. A line always sits inside one, even when the
/// block carries no marker of its own.
ColumnNode onlyBlock(String source) =>
    NaturalBlockParser.parse(source).children.single as ColumnNode;

/// The document's only line, for the many claims about a single line.
TextNode onlyLine(String source) =>
    onlyBlock(source).children.single as TextNode;

/// That line's runs, as the styled spans they are.
List<TextSpanNode> runs(String source) =>
    onlyLine(source).children.cast<TextSpanNode>();
