import 'package:natural_block/delimiter.dart';
import 'package:natural_block/nodes.dart';
import 'package:natural_block/reader.dart';

class NaturalBlockParser {
  NaturalBlockParser();

  ColumnNode parse(String source) {
    final List<ColumnNode> children = [];
    final List<NaturalBlockNode> rowChildren = [];
    final reader = NaturalBlockReader(source: source);
    Delimiter previousDelimiter = Delimiter.none;
    bool wasRow = false;

    while (!reader.isEnd) {
      final result = reader.readUntilDelimiter();
      print(result.delimiter);
      switch ((previousDelimiter, result.delimiter)) {
        case (Delimiter.none, Delimiter.row):
        case (Delimiter.column, Delimiter.row):
        case (Delimiter.row, Delimiter.row):
        case (Delimiter.row, Delimiter.column):
        case (Delimiter.row, Delimiter.none):
          wasRow = true;
          rowChildren.add(ColumnNode(children: _parseLines(result.text)));
          break;

        case (Delimiter.column, Delimiter.column):
        case (Delimiter.column, Delimiter.none):
        case (Delimiter.none, Delimiter.column):
        case (Delimiter.none, Delimiter.none):
          if (!wasRow) {
            children.add(ColumnNode(children: _parseLines(result.text)));
            break;
          }
          wasRow = false;

          final topChildren = children.isEmpty
              ? []
              : children.removeLast().children;
          final rowNode = RowNode(children: [...rowChildren]);
          rowChildren.clear();
          final downChildren = _parseLines(result.text);
          children.add(
            ColumnNode(children: [...topChildren, rowNode, ...downChildren]),
          );

          break;
      }

      previousDelimiter = result.delimiter;
    }

    if (wasRow) {
      final topChildren = children.isEmpty
          ? []
          : children.removeLast().children;
      final rowNode = RowNode(children: [...rowChildren]);
      rowChildren.clear();
      children.add(ColumnNode(children: [...topChildren, rowNode]));
    }

    return ColumnNode(children: children);
  }

  List<ContentNode> _parseLines(String linesText) {
    final lines = linesText.split("\n");

    // 先頭と最後の改行を削除
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
    return TextNode(text: contentText);
  }
}
