import QuartzCore

/// Computes scroll velocity in points per second.
final class ScrollVelocityTracker {

  private var lastOffset: CGFloat = 0
  private var lastTimestamp: CFTimeInterval = 0

  func velocity(currentOffset: CGFloat) -> CGFloat {
    let now = CACurrentMediaTime()

    defer {
      lastOffset = currentOffset
      lastTimestamp = now
    }

    guard lastTimestamp > 0 else { return 0 }

    let deltaOffset = abs(currentOffset - lastOffset)
    let deltaTime = now - lastTimestamp
    guard deltaTime > 0 else { return 0 }

    return deltaOffset / CGFloat(deltaTime)
  }

  func reset() {
    lastOffset = 0
    lastTimestamp = 0
  }
}

