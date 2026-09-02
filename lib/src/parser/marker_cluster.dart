// 【解説】[12/23] レイアウト記号の直後のマーカー列を読む。純粋関数。
// 【解説】
// 【解説】 |~^ のように、1つの区切りが複数のマーカーを持てる。~ が「表かどうか」
// 【解説】 を、< ^ > が「どう置くか」を言う。別々のことを言っているので、
// 【解説】 同じクラスタに同居できる。
// 【解説】
// 【解説】 カーソルを持たず、位置を受け取って「クラスタの終わり」を返す。
// 【解説】 だから単体でテストでき、呼び手の位置を不整合にすることができない。
// 【解説】 以前は parse のループの中に直接書かれていて、scanner の状態を
// 【解説】 進めながら判定していた。
// 【解説】
// 【解説】 align が null 可能なのが要点。「start と言われた」と「何も言われて
// 【解説】 いない」は違う。表の中で列の寄せを継承するのは後者だけ。
// 【解説】 次: lib/src/parser/parser.dart

import '../block_align.dart';
import 'block_marker.dart';

/// What the run of markers just after a layout symbol asked for.
class MarkerCluster {
  /// The alignment the last alignment character named, or null if the
  /// cluster named none. Null is not the same as [BlockAlign.start]: only a
  /// cell that said nothing inherits its column's alignment inside a table.
  final BlockAlign? align;

  /// Whether the cluster asks to cross the table boundary. Each `~` flips
  /// it, so `|~~` asks for nothing; nothing in the language gives a
  /// repeated `~` a meaning, and flipping is just what falls out of `~`
  /// being a toggle.
  final bool togglesTable;

  /// The index just past the cluster.
  final int end;

  const MarkerCluster({
    required this.align,
    required this.togglesTable,
    required this.end,
  });
}

/// Reads the marker cluster starting at [from] -- the position just after a
/// layout symbol.
///
/// Markers share one separator the way decoration characters share one `:`,
/// so `|~^` is a centered table. They describe different things about the
/// one block the separator opens: `~` says what kind of block it is, an
/// alignment character says how it sits. The last alignment character wins,
/// which is why `|~<^>` is an end-aligned table.
///
/// [allowTable] is false after a `=`. A table is a run of rows, so it can
/// only be declared at a `|`; after a separator that divides cells within
/// one row, `~` is ordinary text.
///
/// A pure function over the source, holding no cursor: it reports where the
/// cluster ends and lets the caller move. That is what makes it testable on
/// its own and impossible to leave the caller's position inconsistent.
MarkerCluster readMarkerCluster(
  String source,
  int from, {
  required bool allowTable,
}) {
  BlockAlign? align;
  var togglesTable = false;
  var i = from;

  while (i < source.length) {
    final char = source[i];

    final markerAlign = BlockAlign.byChar[char];
    if (markerAlign != null) {
      align = markerAlign;
      i += 1;
      continue;
    }

    if (allowTable && BlockMarker.byChar[char] == BlockMarker.table) {
      togglesTable = !togglesTable;
      i += 1;
      continue;
    }

    break;
  }

  return MarkerCluster(align: align, togglesTable: togglesTable, end: i);
}
