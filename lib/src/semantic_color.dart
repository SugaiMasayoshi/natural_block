/// Semantic coloring for a span of text: danger/success/info, or none.
/// This is independent of bold emphasis -- a span can be both colored
/// and bold at the same time.
enum SemanticColor { danger, success, info, none }
