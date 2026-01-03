import QuartzCore

/// Stable scroll velocity tracker (points / second)
/// HARD guarantees:
/// - Smoothed velocity (no spikes)
/// - Deterministic decay
/// - Safe for virtualization heuristics
final class ScrollVelocityTracker {

  private var lastOffset: CGFloat = 0
  private var lastTimestamp: CFTimeInterval = 0

  // Exponential moving average
  private var smoothedVelocity: CGFloat = 0

  // Tunables (DO NOT CHANGE)
  private let smoothingFactor: CGFloat = 0.2   // lower = smoother
  private let minDeltaTime: CFTimeInterval = 1.0 / 120.0

  func velocity(currentOffset: CGFloat) -> CGFloat {
    let now = CACurrentMediaTime()

    defer {
      lastOffset = currentOffset
      lastTimestamp = now
    }

    guard lastTimestamp > 0 else { return 0 }

    let dt = now - lastTimestamp
    guard dt >= minDeltaTime else {
      return smoothedVelocity
    }

    let delta = abs(currentOffset - lastOffset)
    let instantVelocity = delta / CGFloat(dt)

    // EMA smoothing (critical)
    smoothedVelocity =
      (instantVelocity * smoothingFactor) +
      (smoothedVelocity * (1 - smoothingFactor))

    return smoothedVelocity
  }

  func reset() {
    lastOffset = 0
    lastTimestamp = 0
    smoothedVelocity = 0
  }
}
