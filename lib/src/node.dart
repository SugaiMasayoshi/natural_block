// 【解説】[2/23] AST。このライブラリの出力そのもの。ここを先に読むと、
// 【解説】 パーサの各処理が「何を作ろうとしているか」が分かる。
// 【解説】
// 【解説】 このファイル自体は束ねているだけで、中身は node/ に1ノード1ファイル。
// 【解説】 各ファイルの import が「自分より下のノードと道具だけ」になっていて、
// 【解説】 それがそのまま階層の証拠になっている。上から下へ読める:
// 【解説】
// 【解説】   natural_block_node.dart  全ての親
// 【解説】   children_equality.dart   子リストの構造的等価性（道具）
// 【解説】   inline_node.dart         行の中に置けるもの
// 【解説】   ├ text_span_node.dart    装飾された文字の連なり
// 【解説】   └ verbatim_node.dart     そのままの文字
// 【解説】   block_node.dart          文書に直接並べられるもの
// 【解説】   ├ text_node.dart         1行
// 【解説】   ├ column_node.dart       行の塊＋寄せ（| が作る。セルでもある）
// 【解説】   ├ row_node.dart          横並び（= が作る）
// 【解説】   └ table_node.dart        行の並び（|~ が宣言する）
// 【解説】   document_node.dart       parse() が返す最上位
// 【解説】
// 【解説】 読みどころは「children の型が全部違う」こと。どのノードも実際に
// 【解説】 入りうる子の型ちょうどを宣言していて、それ以外はコンパイルエラー。
// 【解説】 以前は全部 List<NaturalBlockNode> で、TextSpanNode を ColumnNode の
// 【解説】 子に置いても型が通り、描画時に例外も出ず黙って消える穴があった。
// 【解説】
// 【解説】 sealed をやめて abstract base + final にしてある。Dart の sealed は
// 【解説】 サブタイプが同一ライブラリにいることを要求するので、1ノード1ファイル
// 【解説】 と両立しない。失うのは switch の網羅性検査だけで、これは元々どこでも
// 【解説】 使っていなかった。閉じた集合であることは base と final が保つ。
// 【解説】 次: lib/src/semantic_color.dart と lib/src/block_align.dart（語彙）

/// The node types `NaturalBlockParser.parse` produces.
///
/// One file per node under `node/`, each importing only the nodes below it
/// and the tools it needs -- so the import list of any one file is the
/// hierarchy, checked by the compiler rather than described in a comment.
library;

export 'node/block_node.dart';
export 'node/column_node.dart';
export 'node/document_node.dart';
export 'node/inline_node.dart';
export 'node/natural_block_node.dart';
export 'node/row_node.dart';
export 'node/table_node.dart';
export 'node/text_node.dart';
export 'node/text_span_node.dart';
export 'node/verbatim_node.dart';
