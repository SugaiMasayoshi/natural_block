import 'package:natural_block/natural_block.dart';

/// One line of text, the shape most cells and paragraphs take.
TextNode line(String text) => TextNode(children: [TextSpanNode(text: text)]);

/// A single-line block, which is what a bare paragraph parses to.
ColumnNode block(String text) => ColumnNode(children: [line(text)]);

/// A single-line cell, optionally stating its own alignment.
ColumnNode cell(
  String text, [
  HorizontalAlign align = HorizontalAlign.unstated,
]) => ColumnNode(children: [line(text)], align: align);

/// An empty cell -- what an explicit `^^` holds, and what a short row is
/// padded with when it is drawn.
ColumnNode empty([HorizontalAlign align = HorizontalAlign.unstated]) =>
    ColumnNode(align: align);

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

/// A single-line cell of a table, optionally stating its own alignment.
TableCellNode tableCell(
  String text, [
  HorizontalAlign align = HorizontalAlign.unstated,
]) => TableCellNode(children: [line(text)], align: align);

/// An empty cell of a table -- what an explicit `^^` holds.
TableCellNode emptyTableCell([
  HorizontalAlign align = HorizontalAlign.unstated,
]) => TableCellNode(align: align);

/// The document's only table. A table is content, so it always sits inside
/// a block.
TableNode onlyTable(String source) =>
    onlyBlock(source).children.single as TableNode;

/// The block as the column it is, for the many claims that read straight
/// into a block's contents.
extension AsColumn on NaturalBlockNode {
  ColumnNode get asColumn => this as ColumnNode;
}
