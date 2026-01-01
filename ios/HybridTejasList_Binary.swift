import Foundation
import UIKit
import NitroModules

/**
 * HybridTejasList_Binary
 *
 * High-performance native list engine:
 * - Binary search for visible range
 * - View recycling (constant memory)
 * - Zero JS work on scroll
 * - No AutoLayout
 * - No per-frame allocations
 *
 * Designed as a foundation to outperform FlashList.
 */
final class HybridTejasList_Binary:
  HybridTejasListSpec_base,
  HybridTejasListSpec_protocol
{
  // MARK: - REQUIRED Nitro props (exact names required)
  var itemCount: Double = 0
  var estimatedItemHeight: Double = 0

  /**
   * Estimated height of each item (from JS).
   * REQUIRED. Must be > 0.
   *
   * This property MUST exist to satisfy Nitro protocol.
   * Validation is handled at runtime.
   */
  var estimatedItemSize: Double = 0

  /// JS → Native data access (async later)
  var getItem: (Double) -> Promise<String> = { _ in
    let p = Promise<String>()
    p.reject(
      withError: NSError(
        domain: "HybridTejasList",
        code: 0,
        userInfo: [NSLocalizedDescriptionKey: "getItem not implemented"]
      )
    )
    return p
  }

  // MARK: - Optional native hook (not on hot path)

  var onVisibleRangeChange: ((Double, Double) -> Void)?

  // MARK: - Layout cache (prefix sums)

  private var itemOffsets: [Double] = []
  private var totalContentHeight: Double = 0

  private var lastItemCount: Double = -1
  private var lastEstimatedItemSize: Double = -1

  // MARK: - Visible range (debounced)

  private var lastFirstVisible: Int = -1
  private var lastLastVisible: Int = -1

  // MARK: - Recycler state

  private var visibleViews: [Int: UILabel] = [:]
  private var recycledViews: [UILabel] = []

  // MARK: - HybridObject

  var memorySize: Int { 0 }
  func dispose() {}

  // MARK: - ScrollView (performance tuned)

  private let scrollView: UIScrollView = {
    let sv = UIScrollView()
    sv.alwaysBounceVertical = true
    sv.showsVerticalScrollIndicator = false
    sv.delaysContentTouches = false
    sv.canCancelContentTouches = true
    sv.contentInsetAdjustmentBehavior = .never
    return sv
  }()

  var view: UIView { scrollView }

  // MARK: - Delegate

  private lazy var scrollDelegate = ScrollDelegate(owner: self)

  override init() {
    super.init()
    scrollView.delegate = scrollDelegate
  }

  // MARK: - HybridView lifecycle

  func beforeUpdate() {
    // no-op
  }

  func afterUpdate() {
    // 🚨 Validate required prop
    guard estimatedItemSize > 0 else {
      assertionFailure(
        "HybridTejasList: estimatedItemSize must be provided and > 0"
      )
      return
    }

    // Avoid unnecessary work
    guard
      itemCount != lastItemCount ||
      estimatedItemSize != lastEstimatedItemSize
    else {
      return
    }

    lastItemCount = itemCount
    lastEstimatedItemSize = estimatedItemSize

    rebuildLayout()

    scrollView.contentSize = CGSize(
      width: scrollView.bounds.width,
      height: CGFloat(totalContentHeight)
    )

    recycleAll()
  }

  // MARK: - Layout building (OFF scroll path)

  private func rebuildLayout() {
    itemOffsets.removeAll(keepingCapacity: true)
    itemOffsets.reserveCapacity(Int(itemCount))

    var offset: Double = 0
    for _ in 0..<Int(itemCount) {
      itemOffsets.append(offset)
      offset += estimatedItemSize
    }

    totalContentHeight = offset
  }

  // MARK: - Binary search (O(log n))

  private func firstVisibleIndex(offsetY: Double) -> Int {
    var low = 0
    var high = itemOffsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if itemOffsets[mid] <= offsetY {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return max(0, low - 1)
  }

  private func lastVisibleIndex(offsetY: Double, viewportHeight: Double) -> Int {
    let target = offsetY + viewportHeight
    var low = 0
    var high = itemOffsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if itemOffsets[mid] < target {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return min(itemOffsets.count - 1, low)
  }

  // MARK: - Recycler core

  private func dequeueView() -> UILabel {
    if let view = recycledViews.popLast() {
      return view
    }

    let label = UILabel()
    label.numberOfLines = 1
    label.backgroundColor = .clear
    scrollView.addSubview(label)
    return label
  }

  private func recycleAll() {
    for (_, view) in visibleViews {
      view.removeFromSuperview()
      recycledViews.append(view)
    }

    visibleViews.removeAll()
    lastFirstVisible = -1
    lastLastVisible = -1
  }

  private func updateVisibleViews(first: Int, last: Int) {
    // Remove offscreen
    for (index, view) in visibleViews {
      if index < first || index > last {
        view.removeFromSuperview()
        recycledViews.append(view)
        visibleViews.removeValue(forKey: index)
      }
    }

    // Add visible
    for index in first...last {
      if visibleViews[index] != nil { continue }

      let view = dequeueView()
      visibleViews[index] = view

      // TEMP sync binding (async later)
      view.text = "Row \(index)"

      let y = itemOffsets[index]
      view.frame = CGRect(
        x: 0,
        y: CGFloat(y),
        width: scrollView.bounds.width,
        height: CGFloat(estimatedItemSize)
      )
    }
  }

  // MARK: - Scroll handling (HOT PATH)

  func handleScroll(offsetY: Double, viewportHeight: Double) {
    guard !itemOffsets.isEmpty else { return }

    let first = firstVisibleIndex(offsetY: offsetY)
    let last = lastVisibleIndex(
      offsetY: offsetY,
      viewportHeight: viewportHeight
    )

    if first == lastFirstVisible && last == lastLastVisible {
      return
    }

    lastFirstVisible = first
    lastLastVisible = last

    updateVisibleViews(first: first, last: last)

    onVisibleRangeChange?(Double(first), Double(last))
  }

  // MARK: - Required Nitro methods

  func scrollToIndex(index: Double, animated: Bool) throws {
    let i = Int(index)
    guard i >= 0 && i < itemOffsets.count else { return }

    scrollView.setContentOffset(
      CGPoint(x: 0, y: CGFloat(itemOffsets[i])),
      animated: animated
    )
  }

  func reload() throws {
    afterUpdate()
  }
}

// MARK: - UIScrollViewDelegate (thin)

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
