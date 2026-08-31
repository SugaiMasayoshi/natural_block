import 'package:natural_block/natural_block.dart';

void main() {
  // Every decoration symbol requires a `:` right before it (`:!`, `:?`, `:%`,
  // `:*`, `:+`, `:-`); a bare `!`, `?`, `%`, `*`, `+`, or `-` is always just
  // literal text, so ordinary prose like "C++" or "100%" needs no escaping.
  final source = r'''
|
:++NaturalBlock Parser
:-Simple & Powerful Layout DSL
|
:!NOTE: Welcome to NaturalBlock!
:*Create clean layouts using simple symbols:*
|:?INFO: Context Is Everything=:%SUCCESS: 100% Type-Safe|
Try typing C++ or -100 points without breaking layout!
''';
  final naturalBlock = NaturalBlockParser().parse(source);
  print(naturalBlock);
}
