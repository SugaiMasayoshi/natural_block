// 【解説】[6/21] レイアウト記号の直後に書けるマーカーのうち、寄せではなく
// 【解説】 ブロックの種類そのものを変えるもの。今は表だけ。
// 【解説】
// 【解説】 `~` を選んだ理由は消去法。装飾(+ - ! % ? * @ :)、寄せ(< ^ >)、
// 【解説】 構造(| = \)で埋まっている中、「| の直後」は語頭の位置なので、
// 【解説】 語頭に来やすい記号(# $ " ' ( [ { ` / _)は普通の文章と衝突する。
// 【解説】 # は格子に見えて覚えやすいが、#料理|#旅行 のようなタグの並びが
// 【解説】 黙って壊れる。日本語の範囲表記は全角の 〜(U+301C) なので、
// 【解説】 ASCII の ~(U+007E) との衝突はほとんど起きない。
// 【解説】 次: lib/src/parser/verbatim_region.dart

/// A marker that changes what kind of block a layout separator opens, as
/// opposed to `BlockAlign`, which only changes how that block is positioned.
///
/// Written immediately after an unescaped separator, in the same marker
/// cluster as an alignment character -- `|~^` opens a centered table.
/// Deriving [byChar] from the enum's own values (rather than hand-writing a
/// separate map) means a value can never silently fall out of sync with its
/// lookup entry: add a case here and it's automatically included in [byChar]
/// too.
enum BlockMarker {
  /// Opens a table, or closes the one already open -- it toggles, the same
  /// way a decoration symbol closes what it opened. Recognized only after
  /// `|`: a table is a run of rows, so declaring one at a `=` (which
  /// separates cells *within* a row) would mean a cell that is itself a
  /// table, which the language does not express.
  table('~');

  final String char;
  const BlockMarker(this.char);

  static final Map<String, BlockMarker> byChar = Map.unmodifiable({
    for (final marker in BlockMarker.values) marker.char: marker,
  });
}
