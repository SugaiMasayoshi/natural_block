import 'package:natural_block/parser.dart';

// TODO:余計なColumnNodeが入る問題を修正
// children.add系を.addAllにして_parseLinesを空Listか1つColumnが入ったリストを返すようにする
void main(List<String> arguments) {
  final node = NaturalBlockParser().parse('''|
A
|''');

  print(node);
}

/**
 * start->pipe
 * pipe->end
 * の時にもColumnの範囲なためそこで空Columnが作成されている
 * この問題を修正する
 * 
 * そもそも空のColumnが必要な時はどんな時？　
 */

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
