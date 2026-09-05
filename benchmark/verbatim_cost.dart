// 区間の探し方が何を買っているかを測る。
//
// 走らせ方:
//   dart run benchmark/verbatim_memo.dart
//
// 各文書を何度も測って *最小値* を報告する。平均だと、この機械の
// 他の仕事がそのまま数字に乗ってしまう。

import 'package:natural_block/natural_block.dart';

String repeat(String unit, int times) => List.filled(times, unit).join();

final documents = <String, String>{
  // 区間が多く、しかも行頭にある。メモ化がいちばん効くと主張していた形。
  'ほぼコードブロック': repeat(
    '説明の行\n`\nfinal x = a == b ? 1 : 2;\nfor (var i = 0; i < 10; i++) {}\n`\n続きの文章\n\n',
    200,
  ),

  // 閉じないバッククォートは毎回ソース末尾まで走査して -1 を返す。
  // 走査1回が O(文書長) になる唯一の形。
  '閉じないバッククォート多数': repeat(
    'コマンドは `grep で、値は 3 です。ここは普通の文章がしばらく続きます。\n',
    200,
  ),

  // バッククォートが1つも無い文書。区間の扱いは何も買わないので、
  // 代金だけが見える。
  '散文のみ': repeat(
    '普通の文章がここに入ります。:!強調:! や :+大きく:+ もあります。\n左^右|\n',
    200,
  ),
};

/// [rounds] 回の解析を [samples] 組み行い、いちばん速い組の1回あたりを返す。
double fastest(String source, {int rounds = 200, int samples = 7}) {
  for (var i = 0; i < 50; i++) {
    NaturalBlockParser.parse(source);
  }

  var best = double.infinity;
  for (var s = 0; s < samples; s++) {
    final watch = Stopwatch()..start();
    for (var i = 0; i < rounds; i++) {
      NaturalBlockParser.parse(source);
    }
    watch.stop();
    final per = watch.elapsedMicroseconds / rounds;
    if (per < best) best = per;
  }
  return best;
}

void main() {
  for (final entry in documents.entries) {
    print(
      '${entry.key.padRight(24)} '
      '${entry.value.length.toString().padLeft(7)} 文字  '
      '${fastest(entry.value).toStringAsFixed(0).padLeft(7)} us/回',
    );
  }
}
