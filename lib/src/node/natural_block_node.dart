part of '../node.dart';

/// Everything in the tree. Sealed, so the set of node types is closed and
/// a consumer that handles all of them cannot be caught out by a new one.
sealed class NaturalBlockNode {}

/// How every node compares the children it holds.
///
/// Dart lists compare by identity, so a hand-written `==` that just wrote
/// `children == other.children` would call two trees different whenever
/// they were built separately -- which is every tree a test writes by hand
/// against one the parser produced.
const _childrenEquality = ListEquality<NaturalBlockNode>();
