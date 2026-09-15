// 【解説】[読む順 18/23] raw 区間。書いたとおりに取り出す区間で、中では記号も
// 【解説】 エスケープも読まない。Dart の raw 文字列(r'...')と同じ考え方。
// 【解説】
// 【解説】 - フェンスは連続したバッククォートの数。同じ数で閉じる。閉じがなければ
// 【解説】   文書の終わりまで(表の ~ と同じ)。
// 【解説】 - 行頭のフェンスはブロック(RawNode)、行の途中なら文中(RawSpanNode)。
// 【解説】   どちらかは、振り分ける側(17番と 20番)が cursor.atLineStart で決める。
// 【解説】 - 両端に接した改行は中身に含めない。中身が空の文中の区間は null。
// 【解説】 次: src/parse/text_node.dart
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
