import UIKit

/// Deterministic reuse pool for ListCellView.
/// - Bounded pool
/// - Soft limit (allocation allowed outside pool)
final class ListReusePool {

  private let maxPoolSize: Int = 64
  private var pool: [ListCellView] = []

  /// Returns a reused cell if available
  func dequeueIfAvailable() -> ListCellView? {
    return pool.popLast()
  }

  /// Recycles a cell back into the pool
  func recycle(_ cell: ListCellView) {
    cell.prepareForReuse()
    cell.removeFromSuperview()
    cell.isHidden = false

    guard pool.count < maxPoolSize else {
      // Soft drop — allow GC
      return
    }

    pool.append(cell)
  }

  var count: Int {
    pool.count
  }
}
