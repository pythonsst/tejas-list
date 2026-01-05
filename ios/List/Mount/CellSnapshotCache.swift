import UIKit

/// Caches lightweight snapshot views for fast-scroll masking.
///
/// PURPOSE:
/// - Prevent white flashes during aggressive scrolling
/// - Avoid mounting heavy real cells during velocity spikes
///
/// HARD GUARANTEES:
/// - One snapshot per index (idempotent)
/// - Snapshot views are visually correct but non-interactive
/// - Snapshots are always removable
/// - No layout or measurement coupling
final class CellSnapshotCache {

  /// index → snapshotView
  private var cache: [Int: UIView] = [:]

  /// Capture snapshot if not already present
  func snapshot(cell: UIView, index: Int) {
    guard cache[index] == nil else { return }

    // Use UIKit-native snapshot (fast, safe, GPU-backed)
    guard let snapshot = cell.snapshotView(afterScreenUpdates: false) else {
      return
    }

    snapshot.frame = cell.frame
    snapshot.isUserInteractionEnabled = false

    cache[index] = snapshot
  }

  /// Returns cached snapshot view if present
  func snapshotView(for index: Int) -> UIView? {
    cache[index]
  }

  /// Remove all snapshot views from hierarchy
  func removeAllSnapshots(from container: UIView) {
    for view in cache.values {
      view.removeFromSuperview()
    }
  }

  /// Clear cache (does NOT touch view hierarchy)
  func reset() {
    cache.removeAll()
  }
}
