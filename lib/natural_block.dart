// 【解説】[1/16] パーサ側の公開範囲。まずここで「外に出しているもの」を把握する。
// 【解説】 LayoutSymbol と DecorationAction がここに無いことが重要。記号の対応表は
// 【解説】 パーサの内部実装であって、利用者が触る語彙ではない、という線引き。
// 【解説】 次: lib/src/node.dart（パーサの出力の形を先に知ると以降が読みやすい）

library;

export 'src/block_align.dart';
export 'src/node.dart';
export 'src/parser/parser.dart';
export 'src/semantic_color.dart';
