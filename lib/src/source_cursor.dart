class SourceCursor {
  final String source;

  int _position = 0;

  // The final newline is the one an editor adds when saving.
  SourceCursor(String source)
    : source = switch (source.replaceAll('\r\n', '\n').replaceAll('\r', '\n')) {
        final s when s.endsWith('\n') => s.substring(0, s.length - 1),
        final s => s,
      };

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

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
