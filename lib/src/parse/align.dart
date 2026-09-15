// 【解説】[読む順 11/23] ブロックの始まりの寄せマーカー(< = >)を1文字だけ読む。
// 【解説】
// 【解説】 列(10番)と表のセル(16番)が呼ぶ。ここ以外の < = > はただの文字。
// 【解説】 \ + マーカーなら、\ だけを食べてマーカーは本文に残す。「ここでしか
// 【解説】 記号にならない文字の \ は、それを読む者が食べる」。22番のクラスタも同じ形。
// 【解説】 次: src/parse/row_node.dart
import '../horizontal_align.dart';
import '../markup.dart';
import '../source_cursor.dart';

HorizontalAlign parseAlign(SourceCursor cursor) {
  if (cursor.peek == escapeChar && alignMarkers.containsKey(cursor.peekAt(1))) {
    cursor.take();
    return HorizontalAlign.unstated;
  }
  final marker = alignMarkers[cursor.peek];
  if (marker == null) return HorizontalAlign.unstated;
  cursor.take();
  return marker;
}
