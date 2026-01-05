import UIKit

/// Batches cell size measurements and flushes once per runloop.
/// HARD guarantees:
/// - At most 1 flush per frame
/// - No recursion
/// - No scroll-state coupling
final class MeasurementBatcher {

  // MARK: - State

  private var pending: [Int: CGFloat] = [:]
  private var isScheduled = false

  // 🔑 JANK control hook
  var isSuspended: Bool = false

  /// Called once per batch on main thread
  var onFlush: (([Int: CGFloat]) -> Void)?

  // MARK: - Record

  func record(index: Int, height: CGFloat) {
    guard !isSuspended else { return }
    assert(Thread.isMainThread)

    pending[index] = height

    guard !isScheduled else { return }
    isScheduled = true

    DispatchQueue.main.async { [weak self] in
      self?.flush()
    }
  }

  // MARK: - Flush

  private func flush() {
    assert(Thread.isMainThread)

    guard !pending.isEmpty else {
      isScheduled = false
      return
    }

    // Capture batch atomically
    let batch = pending
    pending.removeAll()
    isScheduled = false

    onFlush?(batch)
  }

  // MARK: - Reset (safety)

  func reset() {
    pending.removeAll()
    isScheduled = false
  }
}
