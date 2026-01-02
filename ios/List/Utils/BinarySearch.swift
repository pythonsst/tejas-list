import CoreGraphics

/// Binary search helpers for visible-range calculation.
/// Operates on a 1-D axis defined by the caller.
enum BinarySearch {

  static func firstVisibleIndex(
    scrollOffset: CGFloat,
    offsets: [CGFloat]
  ) -> Int {
    var low = 0
    var high = offsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if offsets[mid] <= scrollOffset {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return max(0, low - 1)
  }

  static func lastVisibleIndex(
    scrollOffset: CGFloat,
    viewportSize: CGFloat,
    offsets: [CGFloat]
  ) -> Int {
    let target = scrollOffset + viewportSize
    var low = 0
    var high = offsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if offsets[mid] < target {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return min(offsets.count - 1, low)
  }
}
