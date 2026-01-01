import CoreGraphics

enum BinarySearch {

  static func firstVisibleIndex(
    offsetY: CGFloat,
    offsets: [CGFloat]
  ) -> Int {
    var low = 0
    var high = offsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if offsets[mid] <= offsetY {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return max(0, low - 1)
  }

  static func lastVisibleIndex(
    offsetY: CGFloat,
    viewportHeight: CGFloat,
    offsets: [CGFloat]
  ) -> Int {
    let target = offsetY + viewportHeight
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
