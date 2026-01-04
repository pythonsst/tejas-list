final class JankController {

  private(set) var state: JankState = .normal

  // Conservative thresholds
  private let degradeFPS: Double = 48
  private let recoverFPS: Double = 56

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

  func reset() {
    state = .normal
  }
}
