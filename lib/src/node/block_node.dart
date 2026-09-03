part of '../node.dart';


/// A node that can be placed directly in a document, or in whatever else
/// arranges blocks.
///
/// This is the "can stand on its own in the flow" boundary: a `TextSpanNode`
/// is deliberately *not* one, because a styled run only ever exists inside a
/// line. A new block-level construct joins here and becomes placeable
/// everywhere blocks are accepted, with nothing else to wire up.
sealed class BlockNode extends NaturalBlockNode {}
