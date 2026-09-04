part of '../node.dart';

/// The package's front door.
///
/// The tree is built by the nodes themselves -- each reads its own range and
/// stops in front of what is not its own -- so the document node is where
/// the work actually starts. This names that entry point without tying a
/// caller to the root node's type, and it is the only public way in:
/// `DocumentNode._parse` is private so there is one door, not two.
abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) => DocumentNode._parse(source);
}
