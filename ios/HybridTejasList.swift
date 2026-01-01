import UIKit
import NitroModules

final class HybridTejasList: HybridTejasListSpec {

  // MARK: - Tunables
  private let overscan = 5

  // MARK: - View
  let rootView = TejasListRootView()
  var view: UIView { rootView }

  // MARK: - Nitro Props
  var itemCount: Double = 0 { didSet { rebuildLayoutIfNeeded() } }
  var estimatedItemHeight: Double = 0 { didSet { rebuildLayoutIfNeeded() } }

  var onVisibleRangeChange: ((Double, Double) -> Void)?

  // MARK: - Layout Cache (PREFIX SUMS)
  private var heights: [CGFloat] = []
  private var offsets: [CGFloat] = []
  private var totalHeight: CGFloat = 0

  // MARK: - State
  private var lastStart = -1
  private var lastEnd = -1
  private var needsLayout = false
  private var didInitialMount = false

  // MARK: - Init
  override init() {
    super.init()

    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutIfNeeded(force: true)
    }

    rootView.onScroll = { [weak self] offsetY, viewportHeight in
      self?.handleScroll(
        offsetY: offsetY,
        viewportHeight: viewportHeight
      )
    }

    rootView.onCellHeightChange = { [weak self] index, newHeight in
      self?.updateHeight(index: index, height: newHeight)
    }
  }

  // MARK: - Layout Build
  private func rebuildLayoutIfNeeded(force: Bool = false) {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    if rootView.bounds.height == 0 {
      needsLayout = true
      return
    }

    if force || needsLayout {
      needsLayout = false
      buildPrefixSums()
      rootView.setContentHeight(totalHeight)
      emitInitialRange()
    }
  }

  private func buildPrefixSums() {
    let count = Int(itemCount)

    heights = Array(
      repeating: CGFloat(estimatedItemHeight),
      count: count
    )

    offsets = Array(repeating: 0, count: count)

    var running: CGFloat = 0
    for i in 0..<count {
      offsets[i] = running
      running += heights[i]
    }

    totalHeight = running
  }

  // MARK: - Height Update (ANCHOR SAFE)
  private func updateHeight(index: Int, height: CGFloat) {
    guard index < heights.count else { return }
    let delta = height - heights[index]
    guard delta != 0 else { return }

    heights[index] = height

    for i in (index + 1)..<offsets.count {
      offsets[i] += delta
    }

    totalHeight += delta
    rootView.setContentHeight(totalHeight)

    // Scroll anchoring
    let anchorOffset = rootView.scrollView.contentOffset.y
    if offsets[index] < anchorOffset {
      rootView.scrollView.contentOffset.y += delta
    }
  }

  // MARK: - Initial Range
  private func emitInitialRange() {
    guard !didInitialMount else { return }
    didInitialMount = true

    handleScroll(
      offsetY: rootView.scrollView.contentOffset.y,
      viewportHeight: rootView.bounds.height
    )
  }

  // MARK: - Binary Search
  private func firstVisibleIndex(offsetY: CGFloat) -> Int {
    var low = 0
    var high = offsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if offsets[mid] <= offsetY {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return max(0, low - 1)
  }

  private func lastVisibleIndex(offsetY: CGFloat, height: CGFloat) -> Int {
    let target = offsetY + height
    var low = 0
    var high = offsets.count - 1

    while low <= high {
      let mid = (low + high) >> 1
      if offsets[mid] < target {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }

    return min(offsets.count - 1, low)
  }

  // MARK: - Scroll Handling (HOT PATH)
  private func handleScroll(offsetY: CGFloat, viewportHeight: CGFloat) {
    guard !offsets.isEmpty else { return }

    let first =
      max(firstVisibleIndex(offsetY: offsetY) - overscan, 0)

    let last =
      min(
        lastVisibleIndex(
          offsetY: offsetY,
          height: viewportHeight
        ) + overscan,
        offsets.count - 1
      )

    guard first != lastStart || last != lastEnd else {
      return
    }

    lastStart = first
    lastEnd = last

    rootView.mountCells(
      start: first,
      end: last,
      offsets: offsets,
      heights: heights
    )

    onVisibleRangeChange?(
      Double(first),
      Double(last)
    )
  }

  // MARK: - Required Nitro API
  func scrollToIndex(index: Double, animated: Bool) throws {
    let i = Int(index)
    guard i >= 0 && i < offsets.count else { return }

    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: offsets[i]),
      animated: animated
    )
  }
}
