// 【解説】[読む順 1/23] 公開の入口。外から見えるのはここで export する5つだけ。
// 【解説】
// 【解説】 - horizontal_align / tone / span_decoration: 木に載る値
// 【解説】 - nodes: 木そのもの
// 【解説】 - parse/document_node: NaturalBlockParser.parse(唯一の入口)
// 【解説】 src/ の残りは全部非公開。装飾を適用する apply などが外に出ないのは、
// 【解説】 ここで export していないから。
// 【解説】
// 【解説】 読み方: 2〜7 で語彙と木を、8〜23 で読み取りを呼ばれる順にたどる。
// 【解説】 次: src/tone.dart
library;

export 'src/horizontal_align.dart';
export 'src/nodes.dart';
export 'src/parse/document_node.dart';
export 'src/span_decoration.dart';
export 'src/tone.dart';
