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
// 【解説】   何も呼ばない   … 普通の文字(既にリテラルの一部なので何もしなくてよい)
// 【解説】   markConsumed   … 記号だったが、手前に吐き出すリテラルが無い場合
// 【解説】   consume        … 記号で、手前のリテラルを1つの塊として取り出したい場合
// 【解説】   dropCurrentChar… 今読んだ文字だけを無かったことにする(エスケープの \)
// 【解説】
// 【解説】 以前は lastWasEscaped(1つ戻って \ か見る) と dropPrecedingChar が
// 【解説】 あったが、パーサ側を前向き判定に統一したので不要になり、
// 【解説】 dropCurrentChar 1つに置き換わった。
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

  /// Drops the character just read (via [readChar]) from the literal run,
  /// keeping everything before and after it. Used for an escaping backslash:
  /// the caller reads the `\`, decides from [peekNext] that it escapes what
  /// follows, drops it with this, and reads the escaped character normally
  /// so it lands in the literal run as ordinary text.
  void dropCurrentChar() {
    _bufferUpTo(_position - 1);
    _textStart = _position;
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

  /// The cursor's current offset into [source], for a caller that needs to
  /// ask a question about the text ahead before deciding what it is.
  int get position => _position;

  /// Moves the cursor to [index] without touching the literal run.
  ///
  /// Deliberately weaker than [consume] or [dropCurrentChar]: everything
  /// skipped over stays part of the text being accumulated. That is what a
  /// caller wants when it has recognized a region it must not *split* but
  /// also must not *rewrite* -- the layout scan skipping a verbatim region
  /// so a separator inside it never splits a block, while leaving the text
  /// intact for the pass that actually resolves escapes.
  void skipTo(int index) => _position = index;

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
