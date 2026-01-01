import UIKit

/// Computes visible item range from scroll position.
/// HOT PATH – must stay allocation-free and deterministic.
final class ListScrollHandler {

  // MARK: - Dependencies

  /// Layout math provider (prefix sums, offsets, heights)
  weak var layoutEngine: ListLayoutEngine?

  /// Emits (startIndex, endIndex)
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  // MARK: - State

  private var lastStart = -1
  private var lastEnd = -1

  /// Extra items rendered outside viewport
  private let overscan = 5

  // MARK: - Public API (HOT PATH)

  func handleScroll(
    offsetY: CGFloat,
    viewportHeight: CGFloat
  ) {
    guard let layout = layoutEngine, layout.count > 0 else { return }

    let first = max(
      firstVisibleIndex(offsetY: offsetY, layout: layout) - overscan,
      0
    )

    let last = min(
      lastVisibleIndex(
        offsetY: offsetY,
        height: viewportHeight,
        layout: layout
      ) + overscan,
      layout.count - 1
    )

    // De-dup range updates (critical for perf)
    guard first != lastStart || last != lastEnd else { return }

    lastStart = first
    lastEnd = last

    onVisibleRangeChange?(first, last)
  }

  // MARK: - Initial mount (FIXES white screen)

  /// Triggers the first visible range calculation
  /// Call exactly once after layout + contentSize are ready.
  func initialUpdate(viewportHeight: CGFloat) {
    handleScroll(
      offsetY: 0,
      viewportHeight: viewportHeight
    )
  }

  // MARK: - Invalidation

  /// Forces next scroll/update to emit a new range
  func forceUpdate() {
    lastStart = -1
    lastEnd = -1
  }

  // MARK: - Binary Search (O(log n))

  private func firstVisibleIndex(
    offsetY: CGFloat,
    layout: ListLayoutEngine
  ) -> Int {
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
