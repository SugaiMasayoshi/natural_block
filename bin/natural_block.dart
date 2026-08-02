import 'package:natural_block/parser.dart';

// TODO:余計なColumnNodeが入る問題を修正
void main(List<String> arguments) {
  final node = NaturalBlockParser().parse('''
|
A
|
''');

  print(node);
}

/**
 * start->pipe
 * pipe->end
 * の時にもColumnの範囲なためそこで空Columnが作成されている
 * この問題を修正
 */

/**
 * 以下パターンを統一
 * _parseLines関数に入るものは区切り文字から区切り文字まで
 * その時に入った１つめか空最後が空ならそれを消せばよいのでは？
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
