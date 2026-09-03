// 【解説】[2/23] AST。このライブラリの出力そのもの。ここを先に読むと、
// 【解説】 パーサの各処理が「何を作ろうとしているか」が分かる。
// 【解説】
// 【解説】 このファイルは束ねるだけで、中身は node/ に1ノード1ファイル。
// 【解説】 part なので全体で1つのライブラリ。import はここに集約される。
// 【解説】
// 【解説】   natural_block_node.dart  全ての親（sealed）
// 【解説】   children_equality.dart   子リストの構造的等価性（道具）
// 【解説】   inline_node.dart         行の中に置けるもの（sealed）
// 【解説】   ├ text_span_node.dart    装飾された文字の連なり
// 【解説】   └ verbatim_node.dart     そのままの文字
// 【解説】   block_node.dart          文書に直接並べられるもの（sealed）
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
// 【解説】 part を選んだのは sealed を維持するため。Dart の sealed は直接の
// 【解説】 サブタイプが同一ライブラリにあることを要求し、それが連鎖するので、
// 【解説】 BlockNode が NaturalBlockNode を継承する時点で全部が同居になる。
// 【解説】 別ライブラリに分けるには sealed を捨てるしかなく、捨てると switch の
// 【解説】 網羅性検査を失う。
// 【解説】
// 【解説】 代償は、part が自前の import を持てないこと。全ノードが1つの名前空間に
// 【解説】 いるので、下位ノードが上位ノードを参照しても誰も止めない。階層は
// 【解説】 コンパイラではなく規律が守っている。上の図がその規律の表。
// 【解説】 次: lib/src/semantic_color.dart と lib/src/block_align.dart（語彙）

/// The node types `NaturalBlockParser.parse` produces.
///
/// One file per node under `node/`, joined as parts of this one library.
/// That is what keeps the hierarchy `sealed`: Dart requires the direct
/// subtypes of a sealed class to share its library, and the requirement
/// chains, so splitting the nodes into separate libraries would mean giving
/// up sealing the whole tree.
///
/// The cost is that a part cannot carry its own imports, so the file list
/// below is the only statement of the hierarchy -- nothing stops a node
/// referring to one above it. The nodes are ordered here from the bottom up.
library;

import 'package:collection/collection.dart';

import 'block_align.dart';
import 'semantic_color.dart';

part 'node/natural_block_node.dart';
part 'node/children_equality.dart';

part 'node/inline_node.dart';
part 'node/text_span_node.dart';
part 'node/verbatim_node.dart';

part 'node/block_node.dart';
part 'node/text_node.dart';
part 'node/column_node.dart';
part 'node/row_node.dart';
part 'node/table_node.dart';

part 'node/document_node.dart';
