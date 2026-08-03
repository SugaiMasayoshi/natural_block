import 'package:natural_block/parser.dart';

void main(List<String> arguments) {
  final node = NaturalBlockParser().parse('''
|
++ タイトル
こんにちは
|
左
だよ
=
右
だよ
|
１ページ終了
|

|
|
左
だよ
=
右
だよ
|
|
''');

  print(node);
}

/**
 * 以下パターンを統一
 * _parseLines関数に入るものは区切り文字から区切り文字まで
 * その時に入った１つめか空、最後が空ならそれを消せばよいのでは？
 * 
 * |
 * A
 * |
 * 
 * |A|
 * 
 * |A
 * |
 * 
 * |
 * A|
 * 
 */
