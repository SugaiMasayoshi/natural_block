import 'package:natural_block/parser.dart';

void main(List<String> arguments) {
  final node = NaturalBlockParser().parse('''
|
++ タイトル
こんにちは
|左\nだよ=右\nだよ|
１ページ終了
|

|
AAAAA
|左\n左の説明=右\n右の説明|
|
''');

  print(node);
}

/**
 * 以下パターンを統一
 * _parseLines関数に入るものは区切り文字から区切り文字まで
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
