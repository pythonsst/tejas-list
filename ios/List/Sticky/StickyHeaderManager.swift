import CoreGraphics

/// Computes sticky header positioning.
///
/// HARD GUARANTEES:
/// - Pure computation
/// - No UIKit
/// - O(sectionCount)
/// - Safe on scroll hot path
final class StickyHeaderManager {

  struct StickyResult {
    let index: Int
    let y: CGFloat
  }

  func resolveStickyHeader(
    scrollOffset: CGFloat,
    firstVisibleIndex: Int,
    layout: ListLayoutEngine,
    sections: [ListSection]
  ) -> StickyResult? {

    guard
      !sections.isEmpty,
      firstVisibleIndex >= 0
    else { return nil }

    // 1. Find active section header
    guard let section = sections.last(where: { $0.start <= firstVisibleIndex }) else {
      return nil
    }

    let headerIndex = section.headerIndex
    let headerTop = layout.offset(at: headerIndex)
    let headerHeight = layout.height(at: headerIndex)

    // 2. Default pinned position
    var y = scrollOffset

    // 3. Push-off by next section
    if let next = sections.first(where: { $0.start > section.start }) {
      let nextHeaderTop = layout.offset(at: next.headerIndex)
      let pushLimit = nextHeaderTop - headerHeight
      if y > pushLimit {
        y = pushLimit
      }
    }

    // 4. Activate only after header reaches top
    guard y >= headerTop else { return nil }

    return StickyResult(index: headerIndex, y: y)
  }
}
