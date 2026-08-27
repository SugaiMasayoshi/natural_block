import 'package:natural_block/symbol/layout_symbol.dart';
import 'package:natural_block/symbol/semantic_symbol.dart';
import 'package:natural_block/node/node.dart';
import 'package:natural_block/scanner.dart';
import 'package:natural_block/symbol/size_symbol.dart';

class Parser {
  Parser();

  ColumnNode parse(String source) {
    final trimmedSource = source.trim();
    final List<Node> children = [];
    final scanner = Scanner(source: trimmedSource);
    LayoutSymbol previousSymbol = LayoutSymbol.none;

    while (!scanner.isEnd) {
      final result = scanner.scanUntil(LayoutSymbol.scanner);
      final contentNodes = _parseBlock(result.text);

      if (previousSymbol == LayoutSymbol.row || result.symbol == LayoutSymbol.row) {
        children.add(RowNode(children: contentNodes));
      } else {
        children.addAll(contentNodes);
      }

      previousSymbol = result.symbol;
    }

    return ColumnNode(children: children);
  }

  List<ContentNode> _parseBlock(String blockText) {
    final lines = blockText.split('\n');

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(_parseLine).toList();
  }

  ContentNode _parseLine(String lineText) {
    final List<TextSpanNode> children = [];
    final scanner = Scanner(source: lineText);
    int sizeOffset = 0;

    while (!scanner.isEnd) {
      final result = scanner.scanUntil(SizeSymbol.scanner);

      if (result.text.isNotEmpty) {
        children.addAll(_parseSpans(result.text, sizeOffset));
      }

      switch (result.symbol) {
        case SizeSymbol.larger:
          sizeOffset += 1;
        case SizeSymbol.smaller:
          sizeOffset -= 1;
        case SizeSymbol.none:
          break;
      }
    }

    return TextNode(children: children);
  }

  List<TextSpanNode> _parseSpans(String spanText, int sizeOffset) {
    final List<TextSpanNode> children = [];
    final scanner = Scanner(source: spanText);
    SemanticSymbol currentStyle = SemanticSymbol.none;

    while (!scanner.isEnd) {
      final result = scanner.scanUntil(SemanticSymbol.scanner);

      if (result.text.isNotEmpty) {
        children.add(TextSpanNode(
          text: result.text,
          style: currentStyle,
          sizeOffset: sizeOffset,
        ));
      }

      currentStyle = result.symbol == currentStyle
          ? SemanticSymbol.none
          : result.symbol;
    }

    return children;
  }
}

// 後方互換エイリアス（段階的移行用）
typedef NaturalBlockParser = Parser;
