import UIKit

final class ListScrollHandler {

  weak var layoutEngine: ListLayoutEngine?

  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private var lastStart = -1
  private var lastEnd = -1

  private let overscan = 5

  func handleScroll(
    offsetY: CGFloat,
    viewportHeight: CGFloat
  ) {
    guard let layout = layoutEngine, layout.count > 0 else { return }

    let first = max(firstVisibleIndex(offsetY: offsetY, layout: layout) - overscan, 0)
    let last = min(lastVisibleIndex(offsetY: offsetY, height: viewportHeight, layout: layout) + overscan,
                   layout.count - 1)

    guard first != lastStart || last != lastEnd else { return }

    lastStart = first
    lastEnd = last

    onVisibleRangeChange?(first, last)
  }

  func forceUpdate() {
    lastStart = -1
    lastEnd = -1
  }

  // MARK: - Binary Search

  private func firstVisibleIndex(offsetY: CGFloat, layout: ListLayoutEngine) -> Int {
    var low = 0
    var high = layout.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if layout.offset(at: mid) <= offsetY {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return max(0, low - 1)
  }

  private func lastVisibleIndex(
    offsetY: CGFloat,
    height: CGFloat,
    layout: ListLayoutEngine
  ) -> Int {
    let target = offsetY + height
    var low = 0
    var high = layout.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if layout.offset(at: mid) < target {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return min(layout.count - 1, low)
  }
}
