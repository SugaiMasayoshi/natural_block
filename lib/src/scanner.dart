import 'parser/layout_symbol.dart';
import 'parser/verbatim_region.dart';

class Scanned {
  final String text;

  /// The symbol the scan stopped at, or null at the end of the source.
  final String? symbol;

  /// Whether the scan stopped in front of a verbatim region. The cursor is
  /// left on the fence, so the caller decides whether the region is its own.
  final bool atVerbatim;

  const Scanned({required this.text, this.symbol, this.atVerbatim = false});
}

class Scanner {
  final String source;

  int _position = 0;

  Scanner(this.source);

  int get position => _position;

  bool get isEnd => _position >= source.length;

  String get peek => _position < source.length ? source[_position] : '';

  /// The character at [index], or `''` outside the source. Used to ask what
  /// sits against a position without moving.
  String at(int index) =>
      index >= 0 && index < source.length ? source[index] : '';

  /// Whether a verbatim region opens here. Asks without consuming, so a node
  /// can decide whether the region belongs to it before touching it.
  bool get atVerbatimFence =>
      peek == verbatimFenceChar && verbatimRegionAt(source, _position) != null;

  /// Whether the region opening here was written on a line of its own, and
  /// so is a block rather than a run inside a line.
  ///
  /// Stated once, and asked by both sides: the line that must not take it
  /// and the block that must. If the two disagreed, neither would consume
  /// the fence and the caller's loop would never advance.
  bool get atBlockRegion =>
      atVerbatimFence && (_position == 0 || at(_position - 1) == '\n');

  String take() => source[_position++];

  void skipTo(int index) => _position = index;

  /// Consumes the region opening at the cursor and returns its content.
  String takeVerbatim() {
    final region = verbatimRegionAt(source, _position)!;
    _position = region.end;
    return region.text;
  }

  static bool escapesAlwaysActive(String next) =>
      next == r'\' ||
      next == verbatimFenceChar ||
      LayoutSymbol.byChar.containsKey(next);

  Scanned read(
    Set<String> symbols, {
    bool resolveEscapes = false,
    bool stopBeforeVerbatim = false,
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
          if (stopBeforeVerbatim) {
            return Scanned(text: literal(), atVerbatim: true);
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
