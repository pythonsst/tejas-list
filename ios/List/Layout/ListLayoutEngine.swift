import UIKit

/// Prefix-sum based layout engine.
///
/// RESPONSIBILITIES:
/// - Owns item height state
/// - Computes monotonic offsets
/// - Applies batched measurement updates atomically
/// - Exposes read-only layout queries
///
/// HARD GUARANTEES:
/// - Offsets are strictly monotonic
/// - commit() is the ONLY mutation point
/// - Dirty heights are applied deterministically
/// - No UIKit / UIView usage
/// - Section metadata survives layout rebuilds
final class ListLayoutEngine {

  // MARK: - Public configuration

  var itemCount: Int = 0
  var estimatedItemHeight: CGFloat = 0

  /// Layout-level spacing (default = 0)
  var rowSpacing: CGFloat = 0
  var columnSpacing: CGFloat = 0

  /// Scroll axis (drives spacing choice)
  var scrollAxis: ScrollAxis = .vertical

  // MARK: - Layout state

  private(set) var heights: [CGFloat] = []
  private(set) var offsets: [CGFloat] = []
  private(set) var totalHeight: CGFloat = 0

  // MARK: - Sections (Phase-3: Sticky headers)

  private(set) var sections: [ListSection] = []

  func setSections(_ sections: [ListSection]) {
    self.sections = sections
  }

  // MARK: - Dirty measurement state

  private var dirtyHeights: [Int: CGFloat] = [:]

  // MARK: - Build (cold path)

  func build() {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    heights = Array(
      repeating: estimatedItemHeight,
      count: itemCount
    )

    rebuildOffsets()
  }

  // MARK: - Measurement recording (hot path)

  func markHeightDirty(
    at index: Int,
    height: CGFloat
  ) {
    guard index >= 0, index < heights.count else { return }
    dirtyHeights[index] = height
  }

  // MARK: - Commit (THE ONLY MUTATION POINT)

  func commit() {
    guard !dirtyHeights.isEmpty else { return }

    applyDirtyHeights()
    rebuildOffsets()

    dirtyHeights.removeAll()
  }

  // MARK: - Queries (HOT-PATH SAFE)

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

  // MARK: - Internal helpers

  private func applyDirtyHeights() {
    for (index, height) in dirtyHeights {
      heights[index] = height
    }
  }

  /// Recomputes offsets and total content size.
  /// This is the ONLY place spacing is applied.
  private func rebuildOffsets() {
    offsets = Array(repeating: 0, count: heights.count)

    let spacing: CGFloat =
      scrollAxis == .vertical ? rowSpacing : columnSpacing

    var running: CGFloat = 0

    for i in 0..<heights.count {
      offsets[i] = running
      running += heights[i]

      // Add spacing AFTER each item except the last
      if spacing > 0, i < heights.count - 1 {
        running += spacing
      }
    }

    totalHeight = running
  }
}
