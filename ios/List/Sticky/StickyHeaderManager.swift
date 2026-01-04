import CoreGraphics

/// Computes sticky header positioning.
///
/// RESPONSIBILITY:
/// - Decide which header is currently sticky
/// - Compute its vertical offset
///
/// HARD GUARANTEES:
/// - Pure computation (no UIKit)
/// - Deterministic
/// - No allocation
/// - Safe during fast scroll
final class StickyHeaderManager {

  /// Result of a sticky header computation
  struct StickyResult {
    let index: Int
    let yOffset: CGFloat
  }

  /// Computes the active sticky header (if any).
  ///
  /// - Parameters:
  ///   - firstVisibleIndex: first visible item index
  ///   - visibleIndices: currently visible indices (sorted)
  ///   - headerIndices: all sticky header indices (sorted)
  ///   - offsets: item top offsets (prefix sum)
  ///   - heights: item heights
  ///   - scrollOffset: current scroll offset
  ///
  /// - Returns: StickyResult if a header should be pinned
  func computeStickyHeader(
    firstVisibleIndex: Int,
    visibleIndices: [Int],
    headerIndices: [Int],
    offsets: [CGFloat],
    heights: [CGFloat],
    scrollOffset: CGFloat
  ) -> StickyResult? {

    guard
      !headerIndices.isEmpty,
      firstVisibleIndex >= 0
    else { return nil }

    // 1️⃣ Find last header <= first visible item
    guard let headerIndex = headerIndices.last(where: { $0 <= firstVisibleIndex }) else {
      return nil
    }

    let headerTop = offsets[headerIndex]
    let headerHeight = heights[headerIndex]

    // Default pinned position
    var y = scrollOffset

    // 2️⃣ Check if next header is pushing this one
    if let nextHeader = headerIndices.first(where: { $0 > headerIndex }),
       visibleIndices.contains(nextHeader) {

      let nextHeaderTop = offsets[nextHeader]
      let pushLimit = nextHeaderTop - headerHeight

      if scrollOffset > pushLimit {
        y = pushLimit
      }
    }

    // 3️⃣ Only sticky once header has reached the top
    if y < headerTop {
      return nil
    }

    return StickyResult(
      index: headerIndex,
      yOffset: y
    )
  }
}
