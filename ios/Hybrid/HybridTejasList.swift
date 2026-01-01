import UIKit
import NitroModules

final class HybridTejasList: HybridTejasListSpec {

  // MARK: - Engine
  private let engine = ListEngine()

  // MARK: - Nitro required props (MUST be public)

  var itemCount: Double = 0 {
    didSet { engine.itemCount = Int(itemCount) }
  }

  var estimatedItemHeight: Double = 0 {
    didSet { engine.estimatedItemHeight = CGFloat(estimatedItemHeight) }
  }

  var onVisibleRangeChange: ((Double, Double) -> Void)? {
    didSet {
      engine.onVisibleRangeChange = { [weak self] start, end in
        self?.onVisibleRangeChange?(Double(start), Double(end))
      }
    }
  }

  // MARK: - View
  var view: UIView { engine.view }

  // MARK: - Nitro lifecycle
  func scrollToIndex(index: Double, animated: Bool) throws {
    engine.scrollToIndex(Int(index), animated: animated)
  }

  func reload() throws {
    engine.rebuildLayout()
  }
}
