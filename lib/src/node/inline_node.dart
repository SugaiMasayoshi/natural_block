import 'natural_block_node.dart';

/// Something that sits inside a line rather than standing on its own.
///
/// Two kinds, because a line holds two genuinely different things: text
/// carrying decoration, and text the parser stopped reading. Folding the
/// second into the first as a flag would leave a run whose color, emphasis
/// and size can never mean anything -- the same dishonesty `BlockNode`
/// exists to avoid one level up.
abstract base class InlineNode extends NaturalBlockNode {}
