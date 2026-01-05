import QuartzCore
import UIKit

/// Computes scroll velocity in points/sec.
/// - Signed velocity: direction-aware
/// - Absolute velocity: magnitude-only
/// - Frame-safe, allocation-free
final class ScrollVelocityTracker {

  // MARK: - State

  private var lastOffset: CGFloat?
  private var lastTimestamp: CFTimeInterval?

  // MARK: - Public API

  /// Returns signed velocity (points/sec).
  /// Positive = forward scroll, Negative = backward scroll.
  func velocity(currentOffset: CGFloat) -> CGFloat {
    let now = CACurrentMediaTime()

    defer {
      lastOffset = currentOffset
      lastTimestamp = now
    }

    guard
      let lastOffset,
      let lastTimestamp
    else {
      return 0
    }

    let deltaOffset = currentOffset - lastOffset
    let deltaTime = now - lastTimestamp

    guard deltaTime > 0 else {
      return 0
    }

    return deltaOffset / deltaTime
  }

  /// Absolute velocity (magnitude only).
  func absoluteVelocity(currentOffset: CGFloat) -> CGFloat {
    abs(velocity(currentOffset: currentOffset))
  }

  /// Reset internal state (used on reload / layout rebuild).
  func reset() {
    lastOffset = nil
    lastTimestamp = nil
  }
}
