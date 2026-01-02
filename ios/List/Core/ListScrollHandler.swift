import UIKit

final class ListScrollHandler {

  weak var layout: ListLayoutEngine?
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private let overscan = 5
  private var lastStart = -1
  private var lastEnd = -1

  // Default = vertical
  var scrollAxis: ScrollAxis = .vertical

  func handleScroll(
    offset: CGFloat,
    viewportSize: CGFloat
  ) {
    guard
      let layout,
      layout.count > 0,
      viewportSize > 0
    else { return }

    let first = max(
      BinarySearch.firstVisibleIndex(
        offsetY: offset,
        offsets: layout.offsets
      ) - overscan,
      0
    )

    let last = min(
      BinarySearch.lastVisibleIndex(
        offsetY: offset,
        viewportHeight: viewportSize,
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
