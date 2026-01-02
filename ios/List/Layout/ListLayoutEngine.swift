import UIKit

/// 1-D prefix-sum layout engine.
/// Offsets are rebuilt atomically only via commit().
final class ListLayoutEngine {

  private(set) var heights: [CGFloat] = []
  private(set) var offsets: [CGFloat] = []
  private(set) var totalHeight: CGFloat = 0

  var itemCount: Int = 0
  var estimatedItemHeight: CGFloat = 0

  private var isDirty = false

  // MARK: - Initial build

  func build() {
    guard itemCount > 0 else {
      heights = []
      offsets = []
      totalHeight = 0
      isDirty = false
      return
    }

    heights = Array(repeating: estimatedItemHeight, count: itemCount)
    offsets = Array(repeating: 0, count: itemCount)

    var running: CGFloat = 0
    for i in 0..<itemCount {
      offsets[i] = running
      running += heights[i]
    }

    totalHeight = running
    isDirty = false
  }

  var count: Int { heights.count }

  func offset(at index: Int) -> CGFloat {
    offsets[index]
  }

  func height(at index: Int) -> CGFloat {
    heights[index]
  }

  // MARK: - Height invalidation

  func markHeightDirty(at index: Int, height: CGFloat) {
    guard index >= 0, index < heights.count else { return }
    guard heights[index] != height else { return }
    heights[index] = height
    isDirty = true
  }

  // MARK: - Atomic commit

  func commit() {
    guard isDirty else { return }

    var running: CGFloat = 0
    for i in 0..<heights.count {
      offsets[i] = running
      running += heights[i]
    }

    totalHeight = running
    isDirty = false
  }
}
