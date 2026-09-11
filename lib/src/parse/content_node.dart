import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_node.dart';
import 'text_node.dart';
import 'verbatim_node.dart';

/// Reads whichever kind of content starts here.
///
/// Null when it turned out to hold nothing.
ContentNode? parseContentNode(SourceCursor cursor) {
  if (cursor.peek == tableSymbol) return parseTableNode(cursor);
  if (verbatimNodeOpensAt(cursor)) return parseVerbatimNode(cursor);

  final text = parseTextNode(cursor);
  return text.children.isEmpty ? null : text;
}
