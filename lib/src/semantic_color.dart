// 【解説】[3/16] 色の「意味」だけを持つ列挙。赤や緑という具体的な色は持たない。
// 【解説】 何色で描くかはレンダラ側(NaturalBlockTheme)の判断、という責務分離。
// 【解説】 これがあるのでダークモード対応や配色変更がパーサに影響しない。

/// Semantic coloring for a span of text: danger/success/info, or none.
/// This is independent of bold emphasis -- a span can be both colored
/// and bold at the same time.
enum SemanticColor { danger, success, info, none }
