import UIKit

/// Handles safe, bounded relayout animations.
final class RelayoutAnimator {

  struct Config {
    let duration: TimeInterval
    let maxAnimatedDelta: CGFloat
  }

  private let config: Config

  init(
    duration: TimeInterval = 0.18,
    maxAnimatedDelta: CGFloat = 120
  ) {
    self.config = Config(
      duration: duration,
      maxAnimatedDelta: maxAnimatedDelta
    )
  }

  /// Returns true if the change is safe to animate.
  func shouldAnimate(delta: CGFloat) -> Bool {
    abs(delta) <= config.maxAnimatedDelta
  }

  func animate(
    _ animations: @escaping () -> Void
  ) {
    UIView.animate(
      withDuration: config.duration,
      delay: 0,
      options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
      animations: animations,
      completion: nil
    )
  }
}
