// 【解説】[7/16] 文字送りの土台。ここだけは NaturalBlock 言語を一切知らない。
// 【解説】 「今の文字」を返し、リテラル文字列を溜め、呼び手が『今のは記号だった』と
// 【解説】 申告したらそれをリテラルから外す、という機械だけを提供する。
// 【解説】
// 【解説】 中心にあるのは3つの位置:
// 【解説】   _position  … 次に読む場所
// 【解説】   _textStart … 今溜めているリテラルの開始
// 【解説】   _buffer    … エスケープで文字を捨てたときだけ使う継ぎ足し用
// 【解説】 エスケープが無ければ _buffer は作られず、substring 一発で済む。
// 【解説】
// 【解説】 呼び分けの使い分けが読みどころ:
// 【解説】   何も呼ばない … 普通の文字(既にリテラルの一部なので何もしなくてよい)
// 【解説】   markConsumed … 記号だったが、手前に吐き出すリテラルが無い場合
// 【解説】   consume      … 記号で、手前のリテラルを1つの塊として取り出したい場合
// 【解説】 次: lib/src/parser/decoration_parser.dart（このスキャナの最初の利用者）

/// A character-by-character cursor over [source] that accumulates literal
/// text runs (handling backslash-escaped characters) as it goes. Knows
/// nothing about what any particular character means -- that's for the
/// caller to decide by inspecting [readChar]/[peekNext] and telling this
/// scanner whether the character it just read was consumed as markup
/// ([markConsumed], or [consume] when there might be literal text before it
/// worth flushing) -- an ordinary character, including one that turns out
/// to end a cluster without joining it, needs no call at all: it's already
/// part of the literal run.
class LiteralScanner {
  final String source;

  int _position = 0;
  int _textStart = 0;
  StringBuffer? _buffer;

  LiteralScanner(this.source);

  bool get isEnd => _position >= source.length;

  /// The next character to be read, without consuming it (`''` at the end
  /// of the source).
  String get peekNext => _position < source.length ? source[_position] : '';

  /// Reads the current character and advances past it.
  String readChar() {
    final char = source[_position];
    _position += 1;
    return char;
  }

  /// Whether the character just read (via [readChar]) was itself preceded
  /// by a backslash. Assumes `\` is never itself markup -- if it ever
  /// became one, this check would need to also confirm the backslash
  /// wasn't consumed as that.
  bool get lastWasEscaped => _position >= 2 && source[_position - 2] == r'\';

  /// Drops the single character right before the one just read (e.g. an
  /// escaping backslash), keeping the character just read -- and
  /// everything after it -- as literal text. Only valid right after
  /// [lastWasEscaped] is true, which guarantees a preceding character
  /// exists.
  void dropPrecedingChar() {
    assert(_position >= 2);
    _bufferUpTo(_position - 2);
    _textStart = _position - 1;
  }

  /// Ensures [_buffer] exists and has the literal text from [_textStart]
  /// up to [end] written into it.
  void _bufferUpTo(int end) {
    _buffer ??= StringBuffer();
    _buffer!.write(source.substring(_textStart, end));
  }

  /// The character just read was markup, not literal text -- exclude it
  /// from the literal run. Use this when there's no literal text worth
  /// flushing beforehand (e.g. between two decoration characters in the
  /// same cluster); use [consume] otherwise.
  void markConsumed() => _textStart = _position;

  /// The character just read is markup: flushes the literal text
  /// accumulated before it and excludes it from the next literal run.
  String consume() {
    final text = _flush(_position - 1);
    markConsumed();
    return text;
  }

  /// Flushes the literal text accumulated up to the current position --
  /// meant for once scanning has finished, where there's no pending
  /// character left to exclude.
  String flushRemaining() => _flush(_position);

  /// Extracts the literal text up to [end] and advances [_textStart] past
  /// it -- callers that need to skip further still (e.g. past a character
  /// just consumed as markup) do so afterward via [markConsumed].
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
