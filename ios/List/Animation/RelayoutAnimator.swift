import UIKit

final class RelayoutAnimator {

  private let duration: TimeInterval = 0.18
  private let maxAnimatedDelta: CGFloat = 60

  func shouldAnimate(
    delta: CGFloat,
    isScrollingFast: Bool
  ) -> Bool {
    guard !isScrollingFast else { return false }
    return delta > 0 && delta <= maxAnimatedDelta
  }

  func animate(_ updates: @escaping () -> Void) {
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [
        .curveEaseOut,
        .beginFromCurrentState,
        .allowUserInteraction
      ],
      animations: {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        updates()
        CATransaction.commit()
      },
      completion: nil
    )
  }
}
