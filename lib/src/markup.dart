// 【解説】[読む順 7/23] この言語で記号になる文字のすべて。
// 【解説】
// 【解説】 名前はその文字が属する構造で付けている(列・行・表・raw 区間・クラスタ・
// 【解説】 エスケープ)。「区切る」「囲む」のような動作の名前と違い、文字を入れ替えても
// 【解説】 役割が変わっても正しいまま。例外は | で、表の中では行を分ける。
// 【解説】 - alignMarkers: ブロックの始まりでだけ読む寄せ(11番)。
// 【解説】 - DecorationAction: 装飾クラスタの7文字と意味。適用は 23番の apply。
// 【解説】 - layoutChars(| ^): LayoutNode の文字。ノードとノードの間にあり、どの子にも
// 【解説】   属さないので、並べている親が食べる。
// 【解説】 - contentChars(~ `): ContentNode の文字。ノードの一部なので、そのノード自身が
// 【解説】   両端を食べる(中身の大きさで決まるので、終わりも知っている必要がある)。
// 【解説】 - textMarkup: run(21番)が手前で止まる文字。+ - ! % * @ が入って
// 【解説】   いないので、C++ や 100% はエスケープなしでただの文字になる。
// 【解説】 ここまでが語彙。次からは読み取りを、呼ばれる順にたどる。
// 【解説】 次: src/parse/document_node.dart
library;

import 'horizontal_align.dart';

const String columnChar = '|';
const String rowChar = '^';
const String tableChar = '~';
const String rawChar = '`';
const String clusterChar = ':';
const String escapeChar = r'\';

const Map<String, HorizontalAlign> alignMarkers = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

enum DecorationAction {
  larger('+'),
  smaller('-'),
  negative('!'),
  positive('%'),
  emphasis('*'),
  action('@'),
  reset(clusterChar);

  final String char;
  const DecorationAction(this.char);

  static final Set<String> chars = byChar.keys.toSet();

  static final Map<String, DecorationAction> byChar = Map.unmodifiable({
    for (final action in DecorationAction.values) action.char: action,
  });
}

const Set<String> layoutChars = {columnChar, rowChar};

const Set<String> contentChars = {tableChar, rawChar};

const Set<String> textMarkup = {...layoutChars, ...contentChars, clusterChar};
