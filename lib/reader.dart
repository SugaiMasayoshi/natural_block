import 'package:natural_block/delimiter/parser.dart';

class NaturalBlockReader {
  final String source;
  NaturalBlockReader({required this.source});

  int _position = 0;

  bool get isEnd => _position >= source.length;

  ({T delimiter, String text}) readUntilDelimiter<T>(
    MapDelimiterParser<T> parser,
  ) {
    final startPosition = _position;

    while (!isEnd) {
      final char = source[_position];
      final delimiter = parser.parse(char);
      if (delimiter != parser.fallback) {
        final text = source.substring(startPosition, _position);
        _position += 1;
        return (delimiter: delimiter, text: text);
      }

      _position += 1;
    }

    final text = source.substring(startPosition, _position);
    return (delimiter: parser.fallback, text: text);
  }
}
