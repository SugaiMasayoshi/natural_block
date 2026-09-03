import '../block_align.dart';
import '../node.dart';
import 'decoration_parser.dart';
import 'document_assembler.dart';
import 'layout_symbol.dart';
import 'marker_cluster.dart';
import 'source_scan.dart';

bool _isLayoutSymbol(String char) => LayoutSymbol.byChar.containsKey(char);

bool _isNewline(String char) => char == '\n';

abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) {
    final text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final document = DocumentAssembler();
    var start = 0;

    BlockAlign? pendingAlign;

    while (true) {
      final at = nextDelimiter(text, start, _isLayoutSymbol);
      document.addBlock(
        _parseLines(text.substring(start, at)),
        align: pendingAlign,
        endsRow:
            at < text.length &&
            LayoutSymbol.byChar[text[at]] == LayoutSymbol.row,
      );
      pendingAlign = null;
      if (at >= text.length) break;

      final cluster = readMarkerCluster(
        text,
        at + 1,
        allowTable: LayoutSymbol.byChar[text[at]] == LayoutSymbol.column,
      );
      start = cluster.end;

      if (cluster.togglesTable) {
        if (document.inTable) {
          document.closeTable();
          pendingAlign = cluster.align;
        } else {
          document.openTable(cluster.align ?? BlockAlign.start);
        }
      } else {
        pendingAlign = cluster.align;
      }

      if (start >= text.length) break;
    }

    return document.finish();
  }

  static List<TextNode> _parseLines(String block) {
    final lines = <String>[];
    var start = 0;
    while (true) {
      final at = nextDelimiter(block, start, _isNewline);
      lines.add(block.substring(start, at));
      if (at >= block.length) break;
      start = at + 1;
    }

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
