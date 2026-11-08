import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';

/// Whether the region opening at [index] is a block: one that holds a line
/// break.
bool rawBlockAt(String source, int index) =>
    index < source.length &&
    source[index] == rawChar &&
    _scanRegion(source, index).content.contains('\n');

RawNode? parseRawNode(SourceCursor cursor) {
  final start = cursor.position;
  final text = _parseRegion(cursor);
  if (text.isEmpty) return null;
  return RawNode(text: text, start: start, end: cursor.position);
}

RawSpanNode? parseRawSpanNode(SourceCursor cursor) {
  final start = cursor.position;
  final text = _parseRegion(cursor);
  if (text.isEmpty) return null;
  return RawSpanNode(text: text, start: start, end: cursor.position);
}

String _parseRegion(SourceCursor cursor) {
  final (:content, :end) = _scanRegion(cursor.source, cursor.position);
  cursor.jumpTo(end);

  var text = content;
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  return text;
}

({String content, int end}) _scanRegion(String source, int openStart) {
  var fence = 0;
  while (openStart + fence < source.length &&
      source[openStart + fence] == rawChar) {
    fence += 1;
  }

  final contentStart = openStart + fence;
  var search = contentStart;
  while (true) {
    final closerStart = source.indexOf(rawChar, search);
    if (closerStart == -1) {
      return (content: source.substring(contentStart), end: source.length);
    }

    var closerEnd = closerStart;
    while (closerEnd < source.length && source[closerEnd] == rawChar) {
      closerEnd += 1;
    }
    // Only a run exactly as long as the fence closes it; any other is content.
    if (closerEnd - closerStart == fence) {
      return (
        content: source.substring(contentStart, closerStart),
        end: closerEnd,
      );
    }
    search = closerEnd;
  }
}
