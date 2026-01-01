import UIKit
import NitroModules

final class HybridTejasList: HybridTejasListSpec {

  private let overscan = 5

  let rootView = TejasListRootView()
  var view: UIView { rootView }

  // MARK: Props
  var itemCount: Double = 0 { didSet { rebuildHeightsIfNeeded() } }
  var estimatedItemHeight: Double = 0 { didSet { rebuildHeightsIfNeeded() } }

  var onVisibleRangeChange: ((Double, Double) -> Void)?

  // MARK: Variable height cache
  private var itemHeights: [CGFloat] = []
  private var itemOffsets: [CGFloat] = []
  private var totalContentHeight: CGFloat = 0

  // MARK: State
  private var lastStart = -1
  private var lastEnd = -1
  private var needsLayout = false

  override init() {
    super.init()

    rootView.onLayoutReady = { [weak self] in
      self?.layoutIfNeeded(force: true)
    }

    rootView.onScroll = { [weak self] offset, height in
      self?.handleScroll(offsetY: offset, viewportHeight: height)
    }
  }

  // MARK: Layout rebuild

  private func rebuildHeightsIfNeeded() {
    let count = Int(itemCount)
    guard count > 0, estimatedItemHeight > 0 else { return }

    itemHeights = Array(
      repeating: CGFloat(estimatedItemHeight),
      count: count
    )

    rebuildOffsets()
    layoutIfNeeded(force: true)
  }

  private func rebuildOffsets() {
    itemOffsets.removeAll(keepingCapacity: true)
    itemOffsets.reserveCapacity(itemHeights.count)

    var offset: CGFloat = 0
    for h in itemHeights {
      itemOffsets.append(offset)
      offset += h
    }

    totalContentHeight = offset
    rootView.setContentHeight(totalContentHeight)
  }

  private func layoutIfNeeded(force: Bool = false) {
    guard rootView.bounds.height > 0 else {
      needsLayout = true
      return
    }

    if force || needsLayout {
      needsLayout = false
      handleScroll(
        offsetY: rootView.scrollView.contentOffset.y,
        viewportHeight: rootView.bounds.height
      )
    }
  }

  // MARK: Binary search

  private func firstVisibleIndex(offsetY: CGFloat) -> Int {
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

  private func lastVisibleIndex(offsetY: CGFloat, viewportHeight: CGFloat) -> Int {
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

  // MARK: Scroll handling (HOT PATH)

  private func handleScroll(offsetY: CGFloat, viewportHeight: CGFloat) {
    guard !itemOffsets.isEmpty else { return }

    let first = firstVisibleIndex(offsetY: offsetY)
    let last = lastVisibleIndex(
      offsetY: offsetY,
      viewportHeight: viewportHeight
    )

    let start = max(first - overscan, 0)
    let end = min(last + overscan, itemOffsets.count - 1)

    guard start != lastStart || end != lastEnd else { return }

    lastStart = start
    lastEnd = end

    rootView.mountCells(
      start: start,
      end: end,
      offsets: itemOffsets,
      heights: itemHeights
    )

    onVisibleRangeChange?(Double(start), Double(end))
  }

  // MARK: Public API

  func scrollToIndex(index: Double, animated: Bool) throws {
    let i = Int(index)
    guard i >= 0 && i < itemOffsets.count else { return }

    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: itemOffsets[i]),
      animated: animated
    )
  }
}
