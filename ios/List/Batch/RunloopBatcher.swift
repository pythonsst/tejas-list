/// Coalesces multiple updates into one runloop tick.
final class RunloopBatcher {

  private var isScheduled = false
  private var work: (() -> Void)?

  func schedule(_ block: @escaping () -> Void) {
    work = block

    guard !isScheduled else { return }
    isScheduled = true

    DispatchQueue.main.async { [weak self] in
      self?.flush()
    }
  }

  private func flush() {
    isScheduled = false
    work?()
    work = nil
  }
}
