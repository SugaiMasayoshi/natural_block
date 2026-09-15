// 【解説】[読む順 6/23] ソース上の1つの位置と、エスケープの読み方。文法は知らない。
// 【解説】
// 【解説】 - コンストラクタで CRLF と CR を \n に揃える。
// 【解説】 - peek / peekAt は覗くだけ。take / jumpTo が位置を進める。
// 【解説】 - read(markup) は markup か改行の手前まで読んで止まる。途中の \x は
// 【解説】   (x が markup か \ なら)x になる。何が markup かは呼ぶ側が渡す。
// 【解説】 次: src/markup.dart
class SourceCursor {
  final String source;

  int _position = 0;

  SourceCursor(String source)
    : source = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

  bool get atLineStart => _position == 0 || source[_position - 1] == '\n';

  String peekAt(int offset) {
    final index = _position + offset;
    return index >= 0 && index < source.length ? source[index] : '';
  }

  String take() => source[_position++];

  void jumpTo(int index) => _position = index;

  String read(Set<String> markup) {
    final buffer = StringBuffer();
    var literalStart = _position;

    while (_position < source.length) {
      final char = source[_position];
      final next = peekAt(1);

      if (char == r'\' && (next == r'\' || markup.contains(next))) {
        buffer.write(source.substring(literalStart, _position));
        literalStart = _position + 1;
        _position += 2;
        continue;
      }

      if (char == '\n' || markup.contains(char)) break;

      _position += 1;
    }

    buffer.write(source.substring(literalStart, _position));
    return buffer.toString();
  }
}
