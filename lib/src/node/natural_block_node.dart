/// The base type of every node the parser can produce.
///
/// `base` rather than plain `abstract`: a consumer cannot implement this
/// interface, so every node that reaches a renderer really came from the
/// parser. The concrete nodes below it are `final` for the same reason --
/// `NaturalBlockRegistry` looks builders up by exact `runtimeType`, and a
/// subclass a consumer invented would silently render nothing.
///
/// This hierarchy was `sealed` while it lived in one file. Splitting it to a
/// file per node gave that up: Dart requires the subtypes of a sealed class
/// to share its library. What is lost is exhaustiveness checking on a
/// `switch` over node types -- which nothing here used -- and what is kept
/// is the closed set, through `base` and `final`.
abstract base class NaturalBlockNode {}
