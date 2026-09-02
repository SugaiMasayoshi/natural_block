// 【解説】━━━ 読む順番 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 【解説】 全ての解説コメントは行頭が「// 【解説】」で始まる。読み終えたら
// 【解説】 その行を全部消せば元のコードに戻る。番号は2本立てで、
// 【解説】 [n/21] が実装、[テストn/21] がテスト。各ファイルの末尾に「次:」がある。
// 【解説】
// 【解説】 コードの構造を追うなら [1/21] から。言語そのものを知りたいなら
// 【解説】 [テスト1/21](natural_block/test/readme_test.dart)から読むのが早い。
// 【解説】 README の主張がそのまま実行可能な形で並んでいる。
// 【解説】
// 【解説】 実装 ── natural_block
// 【解説】   1 natural_block.dart        公開範囲            ← 今ここ
// 【解説】   2 src/node.dart             AST(出力の形)
// 【解説】   3 src/semantic_color.dart   色の「意味」だけ
// 【解説】   4 src/block_align.dart      寄せ
// 【解説】   5 src/parser/layout_symbol.dart      | と =
// 【解説】   6 src/parser/block_marker.dart       ~(表)
// 【解説】   7 src/parser/verbatim_region.dart    区間の認識(唯一の真実の源)
// 【解説】   8 src/parser/decoration_action.dart  装飾文字の表
// 【解説】   9 src/parser/literal_scanner.dart    文字送りの土台
// 【解説】  10 src/parser/decoration_parser.dart  1行の装飾を解く
// 【解説】  11 src/parser/parser.dart             どこで切れるかを決める
// 【解説】  12 src/parser/document_builder.dart   切れた塊を木にする
// 【解説】 実装 ── natural_block_flutter
// 【解説】  13 natural_block_flutter.dart          公開範囲
// 【解説】  14 src/widget/natural_block_theme.dart 意味 → 見た目
// 【解説】  15 src/widget/text_node_view.dart      葉(文字を描く唯一の場所)
// 【解説】  16 src/widget/column_node_view.dart    縦積み
// 【解説】  17 src/widget/row_node_view.dart       横並び
// 【解説】  18 src/widget/table_node_view.dart     表
// 【解説】  19 src/registry/natural_block_registry.dart 差し替え機構
// 【解説】  20 src/registry/default_builders.dart  既定の描画関数
// 【解説】  21 src/widget/natural_block_view.dart  利用者から見た入口
// 【解説】  番外1 src/widget/natural_block_images.dart 画像の参照実装
// 【解説】  番外2 example/lib/main.dart               実際に動かす場所
// 【解説】
// 【解説】 テストは [テスト1] readme → layout → escape → verbatim → table →
// 【解説】 color → size → action → 正規化 → 等価性 → (Flutter へ)
// 【解説】 rendered_spans → text → verbatim → column → row → table → theme →
// 【解説】 registry → images → 統合 → [テスト21] 見本
// 【解説】━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 【解説】
// 【解説】[1/21] パーサ側の公開範囲。まずここで「外に出しているもの」を把握する。
// 【解説】 LayoutSymbol と DecorationAction がここに無いことが重要。記号の対応表は
// 【解説】 パーサの内部実装であって、利用者が触る語彙ではない、という線引き。
// 【解説】 次: lib/src/node.dart（パーサの出力の形を先に知ると以降が読みやすい）

library;

export 'src/block_align.dart';
export 'src/node.dart';
export 'src/parser/parser.dart';
export 'src/semantic_color.dart';
