import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_node.dart';
import 'text_node.dart';
import 'verbatim_node.dart';

/// Whether content other than a run of text starts at the cursor.
///
/// The dispatch below, asked as a question. A run of text needs the same
/// answer to know where to stop, because it has to end wherever this would
/// pick something else -- and asking it here rather than naming the other
/// kinds keeps "what content can be" in one place.
bool otherContentStartsHere(SourceCursor cursor) =>
    cursor.peek == tableSymbol || verbatimNodeOpensAt(cursor);

/// Reads whichever kind of content starts here.
///
/// Null when it turned out to hold nothing.
ContentNode? parseContentNode(SourceCursor cursor) {
  if (cursor.peek == tableSymbol) return parseTableNode(cursor);
  if (verbatimNodeOpensAt(cursor)) return parseVerbatimNode(cursor);

  final text = parseTextNode(cursor);
  return text.children.isEmpty ? null : text;
}
