import 'package:natural_block/symbol/layout_symbol.dart';
import 'package:natural_block/symbol/semantic_symbol.dart';
import 'package:natural_block/nodes.dart';
import 'package:natural_block/reader.dart';
import 'package:natural_block/symbol/size_symbol.dart';

class NaturalBlockParser {
  NaturalBlockParser();

  ColumnNode parse(String source) {
    final trimmedSource = source.trim();
    final List<NaturalBlockNode> children = [];
    final reader = NaturalBlockReader(source: trimmedSource);
    LayoutSymbol previousSymbol = LayoutSymbol.none;
    while (!reader.isEnd) {
      final result = reader.readUntilSymbol(LayoutSymbol.parser());

      if (previousSymbol == LayoutSymbol.row) {
        final contentNodes = _parseLines(result.text);
        final rowNode = RowNode(children: contentNodes);
        children.add(rowNode);
      } else {
        switch (result.symbol) {
          case LayoutSymbol.column:
          case LayoutSymbol.none:
            final contentNodes = _parseLines(result.text);
            children.addAll(contentNodes);

          case LayoutSymbol.row:
            final contentNodes = _parseLines(result.text);
            final rowNode = RowNode(children: contentNodes);
            children.add(rowNode);
        }
      }

      previousSymbol = result.symbol;
    }

    return ColumnNode(children: children);
  }

  List<ContentNode> _parseLines(String linesText) {
    final lines = linesText.split("\n");

    if (lines.firstOrNull == "") {
      lines.removeAt(0);
    }
    if (lines.lastOrNull == "") {
      lines.removeLast();
    }

    final children = lines.map((line) => _parseContent(line)).toList();

    return children;
  }

  ContentNode _parseContent(String contentText) {
    final List<TextSpanNode> children = [];
    final reader = NaturalBlockReader(source: contentText);
    int sizeOffset = 0;

    while (!reader.isEnd) {
      final result = reader.readUntilSymbol(SizeSymbol.parser());

      if (result.text.isNotEmpty) {
        children.addAll(_parseSemantic(result.text, sizeOffset));
      }

      switch (result.symbol) {
        case SizeSymbol.plus:
          sizeOffset += 1;
          break;
        case SizeSymbol.minus:
          sizeOffset -= 1;
          break;
        case SizeSymbol.none:
          break;
      }
    }

    return TextNode(children: children);
  }

  List<TextSpanNode> _parseSemantic(String contentText, int sizeOffset) {
    final List<TextSpanNode> children = [];
    final reader = NaturalBlockReader(source: contentText);
    SemanticSymbol previousSymbol = SemanticSymbol.none;

    while (!reader.isEnd) {
      final result = reader.readUntilSymbol(SemanticSymbol.parser());

      if (result.text.isNotEmpty) {
        children.add(
          TextSpanNode(
            text: result.text,
            style: previousSymbol,
            sizeOffset: sizeOffset,
          ),
        );
      }

      if (result.symbol == previousSymbol) {
        previousSymbol = SemanticSymbol.none;
      } else {
        previousSymbol = result.symbol;
      }
    }

    return children;
  }
}
