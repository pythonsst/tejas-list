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

  // JS props

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

  // Nitro-required view

  var view: UIView {
    coordinator.rootView
  }

  // Nitro lifecycle

  func reload() throws {
    coordinator.rebuildLayoutAndMount()
  }

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
