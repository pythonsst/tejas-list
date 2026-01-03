import UIKit

/// 1-D prefix-sum layout engine.
/// HARD guarantees:
/// - Offsets are stable before first dirty index
/// - Commits are incremental (O(n - dirtyIndex))
/// - Atomic visibility correctness
final class ListLayoutEngine {

  // MARK: - Storage

  private(set) var heights: [CGFloat] = []
  private(set) var offsets: [CGFloat] = []
  private(set) var totalHeight: CGFloat = 0

  // MARK: - Config

  var itemCount: Int = 0
  var estimatedItemHeight: CGFloat = 0

  // MARK: - Dirty tracking

  private var firstDirtyIndex: Int? = nil

  // MARK: - Build (cold start only)

  func build() {
    guard itemCount > 0 else {
      heights = []
      offsets = []
      totalHeight = 0
      firstDirtyIndex = nil
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
    firstDirtyIndex = nil
  }

  // MARK: - Accessors

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

    if let existing = firstDirtyIndex {
      firstDirtyIndex = min(existing, index)
    } else {
      firstDirtyIndex = index
    }
  }

  // MARK: - Incremental commit

  func commit() {
    guard let start = firstDirtyIndex else { return }

    let baseOffset =
      start == 0
        ? CGFloat(0)
        : offsets[start]

    var running = baseOffset

    for i in start..<heights.count {
      offsets[i] = running
      running += heights[i]
    }

    totalHeight = running
    firstDirtyIndex = nil
  }
}
