part of '../node.dart';


/// A single run of text sharing one decoration state (size, color, emphasis,
/// and actionability).
///
/// A line is split into one of these per run whenever a decoration cluster
/// changes that state partway through.
final class TextSpanNode extends InlineNode {
  /// The literal text of this run, with escaping already resolved.
  final String text;

  /// How many size steps this run is offset from the surrounding default,
  /// e.g. `+2` from two stacked `:+` decorations -- a relative step count,
  /// not an absolute font size, since the parser has no notion of what the
  /// base size actually is.
  final int sizeOffset;

  /// The semantic color applied to this run, or [SemanticColor.none] if no
  /// color decoration is active (see `SemanticColor`).
  final SemanticColor color;

  /// Whether emphasis (`:*`) is active for this run.
  final bool emphasis;

  /// Whether this run is actionable (`:@`) -- something the reader can tap.
  ///
  /// The parser records only *that* the run is actionable, never what
  /// tapping it should do: that decision belongs entirely to the consuming
  /// app (open a URL, jump to a section, open a mention, run a command...).
  /// The tapped payload is simply this run's own [text] -- there is no
  /// separate target field, deliberately, the same way [color] records a
  /// semantic meaning like danger and leaves it to the
  /// theme to decide what red means.
  final bool isAction;

  TextSpanNode({
    required this.text,
    this.sizeOffset = 0,
    this.color = SemanticColor.none,
    this.emphasis = false,
    this.isAction = false,
  });

  @override
  String toString() {
    return 'TextSpanNode(text: $text, sizeOffset: $sizeOffset, '
        'color: $color, emphasis: $emphasis, isAction: $isAction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSpanNode &&
        text == other.text &&
        sizeOffset == other.sizeOffset &&
        color == other.color &&
        emphasis == other.emphasis &&
        isAction == other.isAction;
  }

  @override
  int get hashCode => Object.hash(text, sizeOffset, color, emphasis, isAction);
}
