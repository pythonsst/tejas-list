import UIKit
import NitroModules

/**
 * Nitro wrapper for the native list.
 *
 * Responsibilities:
 * - Receive props from JS
 * - Expose a UIView to Nitro
 * - Forward calls to ListCoordinator
 *
 * Contains NO logic.
 */
final class HybridTejasList: HybridTejasListSpec {

  /// Owns all native behavior
  private let coordinator = ListCoordinator()

  // MARK: - JS Props

  var scrollDirection: ScrollDirection? {
    didSet {
      coordinator.setScrollDirection(scrollDirection)
    }
  }

  var itemCount: Double = 0 {
    didSet {
      coordinator.setItemCount(Int(itemCount))
    }
  }

  var estimatedItemHeight: Double = 0 {
    didSet {
      coordinator.setEstimatedItemHeight(
        CGFloat(estimatedItemHeight)
      )
    }
  }

  var onVisibleRangeChange: ((Double, Double) -> Void)? {
    didSet {
      coordinator.onVisibleRangeChange = { [weak self] start, end in
        self?.onVisibleRangeChange?(
          Double(start),
          Double(end)
        )
      }
    }
  }

  // MARK: - Nitro View

  var view: UIView {
    coordinator.rootView
  }

  // MARK: - Nitro Lifecycle

  func beforeUpdate() {
    // intentionally empty
  }

  func afterUpdate() {
    coordinator.reload()
  }

  // MARK: - Methods

  func scrollToIndex(
    index: Double,
    animated: Bool
  ) throws {
    coordinator.scrollToIndex(
      Int(index),
      animated: animated
    )
  }
}
