import UIKit

/// Represents a completed layout transaction.
/// Once created, layout is immutable.
struct LayoutCommit {
  let heights: [CGFloat]
  let offsets: [CGFloat]
  let totalSize: CGFloat
}
