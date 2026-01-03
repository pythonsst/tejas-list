import UIKit

/// Computes item offsets using prefix sums.
/// Owns height state and layout invalidation.
///
/// GUARANTEES:
/// - Offsets are monotonic
/// - commit() is atomic
/// - Dirty heights are applied deterministically
/// - No UIKit calls
final class ListLayoutEngine {

  // MARK: - Public State

  var itemCount: Int = 0
  var estimatedItemHeight: CGFloat = 0

  private(set) var heights: [CGFloat] = []
  private(set) var offsets: [CGFloat] = []
  private(set) var totalHeight: CGFloat = 0

  // MARK: - Dirty State

  private var dirtyHeights: [Int: CGFloat] = [:]
  private var needsRebuild: Bool = true

  // MARK: - Build (cold path)

  func build() {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    heights = Array(
      repeating: estimatedItemHeight,
      count: itemCount
    )

    rebuildOffsets()
    needsRebuild = false
  }

  // MARK: - Measurement updates (hot, NO mutation)

  func markHeightDirty(
    at index: Int,
    height: CGFloat
  ) {
    guard index >= 0, index < heights.count else { return }
    dirtyHeights[index] = height
  }

  // MARK: - Commit (THE ONLY MUTATION POINT)

  /// Applies dirty heights and recomputes offsets.
  /// This MUST be atomic.
  func commit() {
    guard !dirtyHeights.isEmpty else { return }

    applyDirtyHeights()
    rebuildOffsets()

    dirtyHeights.removeAll()
  }

  // MARK: - Queries (HOT PATH SAFE)

  func offset(at index: Int) -> CGFloat {
    guard index >= 0, index < offsets.count else { return 0 }
    return offsets[index]
  }

  func height(at index: Int) -> CGFloat {
    guard index >= 0, index < heights.count else { return 0 }
    return heights[index]
  }

  var count: Int {
    heights.count
  }

  // MARK: - Internal Helpers (PRIVATE)

  private func applyDirtyHeights() {
    for (index, height) in dirtyHeights {
      heights[index] = height
    }
  }

  private func rebuildOffsets() {
    offsets = Array(repeating: 0, count: heights.count)

    var running: CGFloat = 0
    for i in 0..<heights.count {
      offsets[i] = running
      running += heights[i]
    }

    totalHeight = running
  }
}
