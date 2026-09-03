class LiteralScanner {
  final String source;

  int _position = 0;
  int _textStart = 0;
  StringBuffer? _buffer;

  LiteralScanner(this.source);

  bool get isEnd => _position >= source.length;

  String get peekNext => _position < source.length ? source[_position] : '';

  String readChar() {
    final char = source[_position];
    _position += 1;
    return char;
  }

  void dropCurrentChar() {
    _bufferUpTo(_position - 1);
    _textStart = _position;
  }

  void _bufferUpTo(int end) {
    _buffer ??= StringBuffer();
    _buffer!.write(source.substring(_textStart, end));
  }

  void markConsumed() => _textStart = _position;

  String consume() {
    final text = _flush(_position - 1);
    markConsumed();
    return text;
  }

  String flushRemaining() => _flush(_position);

  int get position => _position;

  void skipTo(int index) => _position = index;

  String _flush(int end) {
    String text;
    if (_buffer != null) {
      _bufferUpTo(end);
      text = _buffer!.toString();
    } else {
      text = source.substring(_textStart, end);
    }
    _buffer = null;
    _textStart = end;
    return text;
  }
}
