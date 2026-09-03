import 'parser/layout_symbol.dart';
import 'parser/verbatim_region.dart';

class Scanned {
  final String text;
  final String? symbol;
  final String? verbatim;

  const Scanned({required this.text, this.symbol, this.verbatim});

  bool get isEnd => symbol == null && verbatim == null;
}

class Scanner {
  final String source;

  int _position = 0;

  Scanner(this.source);

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

  String at(int index) =>
      index >= 0 && index < source.length ? source[index] : '';

  String take() => source[_position++];

  void skipTo(int index) => _position = index;

  static bool escapesAlwaysActive(String next) =>
      next == r'\' ||
      next == verbatimFenceChar ||
      LayoutSymbol.byChar.containsKey(next);

  Scanned read(
    Set<String> symbols, {
    bool resolveEscapes = false,
    bool stopAtVerbatim = false,
  }) {
    bool escapes(String next) =>
        next != '\n' && (escapesAlwaysActive(next) || symbols.contains(next));

    final start = _position;
    StringBuffer? buffer;
    var literalStart = start;

    String literal() {
      if (buffer == null) return source.substring(literalStart, _position);
      buffer.write(source.substring(literalStart, _position));
      return buffer.toString();
    }

    while (_position < source.length) {
      final char = source[_position];

      if (char == r'\' &&
          _position + 1 < source.length &&
          escapes(source[_position + 1])) {
        if (resolveEscapes) {
          buffer ??= StringBuffer();
          buffer.write(source.substring(literalStart, _position));
          literalStart = _position + 1;
        }
        _position += 2;
        continue;
      }

      if (char == verbatimFenceChar) {
        final region = verbatimRegionAt(source, _position);
        if (region != null) {
          if (stopAtVerbatim) {
            final text = literal();
            _position = region.end;
            return Scanned(text: text, verbatim: region.text);
          }
          _position = region.end;
          continue;
        }
      }

      if (symbols.contains(char)) {
        final text = literal();
        _position += 1;
        return Scanned(text: text, symbol: char);
      }

      _position += 1;
    }

    return Scanned(text: literal());
  }
}
