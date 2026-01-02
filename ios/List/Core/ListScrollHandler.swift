import UIKit

/// Computes visible item range from scroll position.
final class ListScrollHandler {

  weak var layout: ListLayoutEngine?
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private let overscan = 5
  private var lastStart = -1
  private var lastEnd = -1

  /// Current scroll axis (set by coordinator)
  var scrollAxis: ScrollAxis = .vertical

  func handleScroll(
    scrollOffset: CGFloat,
    viewportSize: CGFloat
  ) {
    guard
      let layout,
      layout.count > 0,
      viewportSize > 0
    else { return }

    let first = max(
      BinarySearch.firstVisibleIndex(
        scrollOffset: scrollOffset,
        offsets: layout.offsets
      ) - overscan,
      0
    )

    let last = min(
      BinarySearch.lastVisibleIndex(
        scrollOffset: scrollOffset,
        viewportSize: viewportSize,
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
