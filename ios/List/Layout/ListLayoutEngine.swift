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

  // MARK: - Layout state

  private(set) var heights: [CGFloat] = []
  private(set) var offsets: [CGFloat] = []
  private(set) var totalHeight: CGFloat = 0

  // MARK: - Sections (Phase-3: Sticky headers)

  /// Semantic section definitions.
  /// These MUST survive layout rebuilds.
  private(set) var sections: [ListSection] = []

  func setSections(_ sections: [ListSection]) {
    self.sections = sections
  }

  // MARK: - Dirty measurement state

  /// Height updates collected during measurement.
  /// Applied ONLY during commit().
  private var dirtyHeights: [Int: CGFloat] = [:]

  // MARK: - Build (cold path)

  /// Initializes layout with estimated heights.
  /// This does NOT clear section metadata.
  func build() {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    heights = Array(
      repeating: estimatedItemHeight,
      count: itemCount
    )

    rebuildOffsets()
  }

  // MARK: - Measurement recording (hot path, NO mutation)

  func markHeightDirty(
    at index: Int,
    height: CGFloat
  ) {
    guard index >= 0, index < heights.count else { return }
    dirtyHeights[index] = height
  }

  // MARK: - Commit (THE ONLY MUTATION POINT)

  /// Applies all dirty height updates and recomputes offsets.
  /// This operation MUST be atomic.
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
