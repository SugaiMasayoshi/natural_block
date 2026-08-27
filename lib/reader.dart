import 'package:natural_block/symbol/parser.dart';

class NaturalBlockReader {
  final String source;
  NaturalBlockReader({required this.source});

  int _position = 0;

  bool get isEnd => _position >= source.length;

  ({T symbol, String text}) readUntilSymbol<T>(MapSymbolParser<T> parser) {
    int startPosition = _position;
    StringBuffer? buffer;

    while (!isEnd) {
      final char = source[_position];
      final symbol = parser.parse(char);

      if (symbol != parser.fallback) {
        if (_position > 0 && source[_position - 1] == r'\') {
          buffer ??= StringBuffer();
          buffer.write(source.substring(startPosition, _position - 1));
          buffer.write(char);
          _position += 1;
          startPosition = _position;
          continue;
        }

        final text = buffer != null
            ? (buffer..write(source.substring(startPosition, _position)))
                  .toString()
            : source.substring(startPosition, _position);
        _position += 1;
        return (symbol: symbol, text: text);
      }

      _position += 1;
    }

    final text = buffer != null
        ? (buffer..write(source.substring(startPosition, _position))).toString()
        : source.substring(startPosition, _position);
    return (symbol: parser.fallback, text: text);
  }
}
