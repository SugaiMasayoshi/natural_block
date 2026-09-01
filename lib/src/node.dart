import 'package:collection/collection.dart';

import 'block_align.dart';
import 'semantic_color.dart';

/// Deep, order-sensitive equality (and matching hash) for a node's
/// `children` list, shared by every [NaturalBlockNode] subclass below.
const _childrenEquality = ListEquality<NaturalBlockNode>();

/// The base type of every node the parser can produce -- a plain marker so
/// that layout nodes and content nodes can be mixed freely in a single
/// children list.
sealed class NaturalBlockNode {}

/// Shared base for the two node kinds that arrange other nodes rather than
/// holding text directly.
sealed class LayoutNode<T extends NaturalBlockNode> extends NaturalBlockNode {
  final List<T> children;
  LayoutNode({required this.children});
}

/// A vertical arrangement, produced by the `|` separator, and also used to
/// hold the stacked lines of a single [RowNode] cell. A [ColumnNode]'s
/// children can be any node -- including further layout nodes -- since
/// columns are the outermost structure the parser always returns.
class ColumnNode extends LayoutNode<NaturalBlockNode> {
  /// How this column's children are aligned horizontally, set by an
  /// alignment marker (`<`, `^`, `>`) written immediately after the layout
  /// separator that opened this block. Defaults to [BlockAlign.start] when
  /// no marker was given.
  final BlockAlign align;

  ColumnNode({required super.children, this.align = BlockAlign.start});
  @override
  String toString() {
    return 'ColumnNode(children: $children, align: $align)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}

/// A horizontal arrangement, produced by the `=` separator.
///
/// A [RowNode] holds every cell of one visual row -- each child is a
/// [ColumnNode] holding that cell's stacked lines (a cell with a single line
/// is simply a one-child [ColumnNode]). The row boundary is therefore
/// explicit structure: there is no convention of grouping sibling nodes back
/// up to find where one row ends and the next begins.
class RowNode extends LayoutNode<ColumnNode> {
  RowNode({required super.children});
  @override
  String toString() {
    return 'RowNode(children: $children)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// Shared base for the two node kinds that hold actual text rather than
/// arranging other nodes.
sealed class ContentNode extends NaturalBlockNode {}

/// A single run of text sharing one decoration state (size, color, and
/// emphasis) -- a [TextNode] is split into one [TextSpanNode] per run
/// whenever a decoration cluster changes that state partway through a line.
class TextSpanNode extends ContentNode {
  /// The literal text of this run, with escaping already resolved.
  final String text;

  /// How many size steps this run is offset from the surrounding default,
  /// e.g. `+2` from two stacked `:+` decorations -- a relative step count,
  /// not an absolute font size, since the parser has no notion of what the
  /// base size actually is.
  final int sizeOffset;

  /// The semantic color applied to this run, or [SemanticColor.none] if no
  /// color decoration is active.
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
  /// semantic meaning like [SemanticColor.danger] and leaves it to the
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
    return 'TextSpanNode(text: $text, sizeOffset: $sizeOffset, color: $color, emphasis: $emphasis, isAction: $isAction)';
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
  int get hashCode =>
      Object.hash(text, sizeOffset, color, emphasis, isAction);
}

/// A single line of text, broken into one or more [TextSpanNode] children
/// wherever its decoration state changes partway through.
class TextNode extends ContentNode {
  final List<TextSpanNode> children;
  TextNode({this.children = const []});

  @override
  String toString() {
    return 'TextNode(children: $children)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
