import 'package:natural_block/delimiter.dart';

class NaturalBlockReader {
  final String source;
  NaturalBlockReader({required this.source});

  int _position = 0;

  bool get isEnd => _position >= source.length;

  ({Delimiter delimiter, String text}) readUntilDelimiter() {
    final startPosition = _position;

    while (!isEnd) {
      final char = source[_position];
      final delimiter = Delimiter.fromChar(char);
      if (delimiter != Delimiter.none) {
        final text = source.substring(startPosition, _position);
        _position += 1;
        return (delimiter: delimiter, text: text);
      }

      _position += 1;
    }

    final text = source.substring(startPosition, _position);
    return (delimiter: Delimiter.none, text: text);
  }
}
