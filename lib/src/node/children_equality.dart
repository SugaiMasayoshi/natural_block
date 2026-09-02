import 'package:collection/collection.dart';

import 'natural_block_node.dart';

/// Deep, order-sensitive equality (and matching hash) for a node's
/// `children` list.
///
/// Every node with children uses this one instance rather than writing the
/// comparison itself. Structural equality is what lets a test say
/// `expect(parse(source), DocumentNode(children: [...]))`, so the whole
/// suite rests on it being right in one place.
const childrenEquality = ListEquality<NaturalBlockNode>();
