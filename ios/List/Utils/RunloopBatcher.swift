import Foundation

/// Coalesces multiple requests into a single execution
/// on the next runloop tick.
///
/// Guarantees:
/// - Executes at most once per runloop
/// - Drops duplicate schedules
/// - No recursion
final class RunloopBatcher {

  private var isScheduled = false
  private var pendingBlock: (() -> Void)?

  /// Schedule a block to run once on the next runloop.
  func schedule(_ block: @escaping () -> Void) {
    pendingBlock = block

    guard !isScheduled else { return }
    isScheduled = true

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      self.isScheduled = false
      let work = self.pendingBlock
      self.pendingBlock = nil

      work?()
    }
  }

  /// Cancel any pending work.
  func cancel() {
    pendingBlock = nil
    isScheduled = false
  }
}
