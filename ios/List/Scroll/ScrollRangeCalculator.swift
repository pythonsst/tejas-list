import UIKit

struct ScrollRangeCalculator {

  static func visibleRange(
    scrollOffset: CGFloat,
    viewportSize: CGFloat,
    offsets: [CGFloat],
    overscan: Int
  ) -> (start: Int, end: Int)? {
    guard !offsets.isEmpty else { return nil }

    let first = max(
      BinarySearch.firstVisibleIndex(
        scrollOffset: scrollOffset,
        offsets: offsets
      ) - overscan,
      0
    )

    let last = min(
      BinarySearch.lastVisibleIndex(
        scrollOffset: scrollOffset,
        viewportSize: viewportSize,
        offsets: offsets
      ) + overscan,
      offsets.count - 1
    )

    return first <= last ? (first, last) : nil
  }
}
