import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';

RawNode parseRawNode(SourceCursor cursor) =>
    RawNode(text: _parseRegion(cursor));

RawSpanNode? parseRawSpanNode(SourceCursor cursor) {
  final text = _parseRegion(cursor);
  return text.isEmpty ? null : RawSpanNode(text: text);
}

String _parseRegion(SourceCursor cursor) {
  final source = cursor.source;
  final openIndex = cursor.position;

  var fence = 0;
  while (openIndex + fence < source.length &&
      source[openIndex + fence] == rawChar) {
    fence += 1;
  }

  final contentStart = openIndex + fence;
  final closerStart = source.indexOf(rawChar * fence, contentStart);
  final closed = closerStart != -1;

  var text = source.substring(
    contentStart,
    closed ? closerStart : source.length,
  );
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);

  cursor.jumpTo(closed ? closerStart + fence : source.length);
  return text;
}
