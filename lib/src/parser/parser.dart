import '../node.dart';

abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) => DocumentNode.parse(source);
}
