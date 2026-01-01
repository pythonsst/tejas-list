import Foundation
import UIKit
import NitroModules

/**
 * Binary Search – Step 1
 * Native scroll + visible range calculation (Nitro-safe).
 */
final class HybridTejasList_Binary:
  HybridTejasListSpec_base,
  HybridTejasListSpec_protocol
{
  var estimatedItemHeight: Double = 0.0
  
  private var itemOffsets: [Double] = []
  private var totalContentHeight: Double = 0
  
  // MARK: - Native state (must have defaults)

  /// Optional helper for debugging / future JS event
  var onVisibleRangeChange: ((Double, Double) -> Void)?

  // MARK: - HybridObject requirements

  var memorySize: Int {
    0
  }

  func dispose() {
    // no-op
  }

  // MARK: - View

  private let scrollView: UIScrollView = {
    let sv = UIScrollView()
    sv.alwaysBounceVertical = true
    sv.showsVerticalScrollIndicator = true
    return sv
  }()

  var view: UIView {
    scrollView
  }

  // MARK: - Delegate helper (NSObject-backed)

  private lazy var scrollDelegate = ScrollDelegate(owner: self)

  // MARK: - Init (IMPORTANT: no custom params)

  override init() {
    super.init()
    scrollView.delegate = scrollDelegate
  }

  // MARK: - HybridView lifecycle

  func beforeUpdate() {
    // no-op
  }

  func afterUpdate() {
    rebuildLayout()
    scrollView.contentSize = CGSize(
      width: scrollView.bounds.width,
      height: CGFloat(totalContentHeight)
    )
  }

  private func rebuildLayout() {
    itemOffsets.removeAll(keepingCapacity: true)
    itemOffsets.reserveCapacity(Int(itemCount))

    var offset: Double = 0

    for _ in 0..<Int(itemCount) {
      itemOffsets.append(offset)
      offset += estimatedItemSize // later: per-item height
    }

    totalContentHeight = offset
  }

  // MARK: - Binary search helpers
  


  private func firstVisibleIndex(offsetY: Double) -> Int {
    guard !itemOffsets.isEmpty else { return 0 }
    var low = 0
    var high = itemOffsets.count - 1

    while low <= high {
      let mid = (low + high) / 2
      if itemOffsets[mid] <= offsetY {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return max(0, low - 1)
  }

  private func lastVisibleIndex(offsetY: Double, viewportHeight: Double) -> Int {
    guard !itemOffsets.isEmpty else { return 0 }
    let target = offsetY + viewportHeight

    var low = 0
    var high = itemOffsets.count - 1

    while low <= high {
      let mid = (low + high) / 2
      if itemOffsets[mid] < target {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return min(itemOffsets.count - 1, low)
  }


  // MARK: - Required props (from Nitro spec)

  var itemCount: Double = 0
  var estimatedItemSize: Double = 0

  var getItem: (Double) -> Promise<String> = { _ in
    let promise = Promise<String>()
    promise.reject(
      withError: NSError(
        domain: "HybridTejasList_Binary",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "getItem not implemented"]
      )
    )
    return promise
  }

  // MARK: - Required methods

  func scrollToIndex(index: Double, animated: Bool) throws {
    let i = Int(index)
    guard i >= 0 && i < itemOffsets.count else { return }

    let y = itemOffsets[i]
    scrollView.setContentOffset(
      CGPoint(x: 0, y: CGFloat(y)),
      animated: animated
    )
  }


  func reload() throws {
    afterUpdate()
  }

  // MARK: - Visible range calculation (O(1) for now)

  func handleScroll(offsetY: Double, viewportHeight: Double) {
    guard !itemOffsets.isEmpty else { return }

    let first = firstVisibleIndex(offsetY: offsetY)
    let last = lastVisibleIndex(
      offsetY: offsetY,
      viewportHeight: viewportHeight
    )

    onVisibleRangeChange?(Double(first), Double(last))
  }

}

// MARK: - UIScrollView Delegate (NSObject-backed)

final class ScrollDelegate: NSObject, UIScrollViewDelegate {

  private unowned let owner: HybridTejasList_Binary

  init(owner: HybridTejasList_Binary) {
    self.owner = owner
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    owner.handleScroll(
      offsetY: Double(scrollView.contentOffset.y),
      viewportHeight: Double(scrollView.bounds.height)
    )
  }
}
