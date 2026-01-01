import UIKit

final class ListLayoutEngine {

  // MARK: - Storage
  private(set) var heights: [CGFloat] = []
  private(set) var offsets: [CGFloat] = []

  private(set) var totalHeight: CGFloat = 0

  // MARK: - Inputs
  var itemCount: Int = 0
  var estimatedItemHeight: CGFloat = 0

  // MARK: - Build layout (prefix sums)
  func build() {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    heights = Array(repeating: estimatedItemHeight, count: itemCount)
    offsets = Array(repeating: 0, count: itemCount)

    var running: CGFloat = 0
    for i in 0..<itemCount {
      offsets[i] = running
      running += heights[i]
    }

    totalHeight = running
  }

  // MARK: - Accessors (REQUIRED)
  var count: Int { heights.count }

  func offset(at index: Int) -> CGFloat {
    offsets[index]
  }

  func height(at index: Int) -> CGFloat {
    heights[index]
  }

  // MARK: - Dynamic height update (ANCHOR SAFE)
  @discardableResult
  func updateHeight(at index: Int, height: CGFloat) -> CGFloat {
    guard index < heights.count else { return 0 }

    let delta = height - heights[index]
    guard delta != 0 else { return 0 }

    heights[index] = height

    for i in (index + 1)..<offsets.count {
      offsets[i] += delta
    }

    totalHeight += delta
    return delta
  }
}
