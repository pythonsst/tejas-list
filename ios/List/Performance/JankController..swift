final class JankController {

  // MARK: - State

  private(set) var state: JankState = .normal

  // MARK: - Thresholds

  private let degradeFPS: Double = 48
  private let recoverFPS: Double = 56

  // MARK: - Update

  /// Returns true if state changed
  func update(fps: Double) -> Bool {
    switch state {
    case .normal:
      if fps < degradeFPS {
        state = .degraded
        return true
      }

    case .degraded:
      if fps > recoverFPS {
        state = .normal
        return true
      }
    }

    return false
  }

  // MARK: - Reset

  func reset() {
    state = .normal
  }
}
