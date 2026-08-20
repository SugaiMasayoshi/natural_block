import 'package:natural_block/symbol/layout_symbol.dart';
import 'package:natural_block/symbol/semantic_symbol.dart';
import 'package:natural_block/nodes.dart';
import 'package:natural_block/reader.dart';

class NaturalBlockParser {
  NaturalBlockParser();

  ColumnNode parse(String source) {
    final trimmedSource = source.trim();
    final List<ColumnNode> pages = [];
    final List<NaturalBlockNode> columnChildren = [];
    final List<NaturalBlockNode> rowChildren = [];
    final reader = NaturalBlockReader(source: trimmedSource);
    LayoutSymbol previousDelimiter = LayoutSymbol.none;

    while (!reader.isEnd) {
      final result = reader.readUntilDelimiter(LayoutSymbol.parser());
      switch ((previousDelimiter, result.delimiter)) {
        case (LayoutSymbol.none, LayoutSymbol.row):
        case (LayoutSymbol.column, LayoutSymbol.row):
        case (LayoutSymbol.row, LayoutSymbol.row):
        case (LayoutSymbol.row, LayoutSymbol.column):
        case (LayoutSymbol.row, LayoutSymbol.none):
          rowChildren.addAll(_parseRowContents(result.text));
          break;

        case (LayoutSymbol.column, LayoutSymbol.column):
        case (LayoutSymbol.column, LayoutSymbol.none):
        case (LayoutSymbol.none, LayoutSymbol.column):
        case (LayoutSymbol.none, LayoutSymbol.none):
          if (rowChildren.isNotEmpty) {
            final topChildren = [...columnChildren];
            columnChildren.clear();
            final middleRowChildren = [...rowChildren];
            rowChildren.clear();
            final downChildren = _parseLines(result.text);

            final List<NaturalBlockNode> combineList = [
              ...topChildren,
              if (middleRowChildren.isNotEmpty)
                RowNode(children: middleRowChildren),
              ...downChildren,
            ];
            pages.add(ColumnNode(children: combineList));
            break;
          }

          pages.addAll(_parseColumnContents([...columnChildren]));
          columnChildren.clear();
          columnChildren.addAll(_parseLines(result.text));
          break;
      }

      previousDelimiter = result.delimiter;
    }

    if (rowChildren.isNotEmpty || columnChildren.isNotEmpty) {
      final topChildren = [...columnChildren];
      columnChildren.clear();
      final middleRowChildren = [...rowChildren];
      rowChildren.clear();
      final List<NaturalBlockNode> combineList = [
        ...topChildren,
        if (middleRowChildren.isNotEmpty) RowNode(children: middleRowChildren),
      ];

      pages.add(ColumnNode(children: combineList));
    }

    return ColumnNode(children: pages);
  }

  List<NaturalBlockNode> _parseRowContents(String linesText) {
    final contents = _parseLines(linesText);

    if (contents.isEmpty) {
      return [];
    }

    if (contents.length == 1) {
      return [contents.first];
    }

    return [ColumnNode(children: contents)];
  }

  List<ColumnNode> _parseColumnContents(List<NaturalBlockNode> children) {
    if (children.isEmpty) {
      return [];
    }

    return [ColumnNode(children: children)];
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
    SemanticSymbol previousDelimiter = SemanticSymbol.none;

    while (!reader.isEnd) {
      final result = reader.readUntilDelimiter(SemanticSymbol.parser());

      if (result.text.isNotEmpty) {
        children.add(TextSpanNode(text: result.text, style: previousDelimiter));
      }

      if (result.delimiter == previousDelimiter) {
        previousDelimiter = SemanticSymbol.none;
      } else {
        previousDelimiter = result.delimiter;
      }
    }

    return TextNode(children: children);
  }
}
