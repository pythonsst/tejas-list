import UIKit

final class ListScrollHandler {

  weak var layout: ListLayoutEngine?
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private let overscan = 5
  private var lastStart = -1
  private var lastEnd = -1

  func handleScroll(
    offsetY: CGFloat,
    viewportHeight: CGFloat
  ) {
    guard
      let layout,
      layout.count > 0,
      viewportHeight > 0
    else { return }

    let first = max(
      BinarySearch.firstVisibleIndex(
        offsetY: offsetY,
        offsets: layout.offsets
      ) - overscan,
      0
    )

    let last = min(
      BinarySearch.lastVisibleIndex(
        offsetY: offsetY,
        viewportHeight: viewportHeight,
        offsets: layout.offsets
      ) + overscan,
      layout.count - 1
    )

    guard first != lastStart || last != lastEnd else { return }

    lastStart = first
    lastEnd = last
    onVisibleRangeChange?(first, last)
  }

  func reset() {
    lastStart = -1
    lastEnd = -1
  }
}
