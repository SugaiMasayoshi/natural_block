import 'package:natural_block/delimiter/layout_delimiter.dart';
import 'package:natural_block/delimiter/semantic_role.dart';
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
    LayoutDelimiter previousDelimiter = LayoutDelimiter.none;

    while (!reader.isEnd) {
      final result = reader.readUntilDelimiter(LayoutDelimiter.parser());
      switch ((previousDelimiter, result.delimiter)) {
        case (LayoutDelimiter.none, LayoutDelimiter.row):
        case (LayoutDelimiter.column, LayoutDelimiter.row):
        case (LayoutDelimiter.row, LayoutDelimiter.row):
        case (LayoutDelimiter.row, LayoutDelimiter.column):
        case (LayoutDelimiter.row, LayoutDelimiter.none):
          rowChildren.addAll(_parseRowContents(result.text));
          break;

        case (LayoutDelimiter.column, LayoutDelimiter.column):
        case (LayoutDelimiter.column, LayoutDelimiter.none):
        case (LayoutDelimiter.none, LayoutDelimiter.column):
        case (LayoutDelimiter.none, LayoutDelimiter.none):
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
    SemanticRole previousDelimiter = SemanticRole.none;

    while (!reader.isEnd) {
      final result = reader.readUntilDelimiter(SemanticRole.parser());

      if (result.text.isNotEmpty) {
        children.add(TextSpanNode(text: result.text, style: previousDelimiter));
      }

      if (result.delimiter == previousDelimiter) {
        previousDelimiter = SemanticRole.none;
      } else {
        previousDelimiter = result.delimiter;
      }
    }

    return TextNode(children: children);
  }
}
