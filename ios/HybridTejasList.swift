import UIKit

final class HybridTejasList: HybridTejasListSpec {

  // MARK: - Required by Nitro
  
  // MARK: - Overscan
  private let overscanCount = 5

  let rootView = TejasListRootView()
  var view: UIView { rootView }

  // MARK: - Props (from JS)

  var itemCount: Double = 0 {
    didSet {
      print("🟣 [HYBRID:itemCount]", itemCount)
      updateLayout()
    }
  }

  var estimatedItemHeight: Double = 0 {
    didSet {
      print("🟣 [HYBRID:estimatedItemHeight]", estimatedItemHeight)
      updateLayout()
    }
  }

  var onVisibleRangeChange: ((Double, Double) -> Void)?

  // MARK: - Internal State

  private var needsLayoutUpdate = false
  private var visibleStart = -1
  private var visibleEnd = -1

  override init() {
    super.init()

    print("🟣 [HYBRID:init]")

    rootView.onLayout = { [weak self] in
      guard let self = self else { return }

      print("🟣 [HYBRID:onLayout]")

      if self.needsLayoutUpdate {
        self.needsLayoutUpdate = false
        self.updateLayout()
      }
    }

    rootView.onScroll = { [weak self] offsetY, viewportHeight in
      self?.handleScroll(offsetY: offsetY, viewportHeight: viewportHeight)
    }
  }

  // MARK: - Methods (from JS)

  func scrollToIndex(index: Double, animated: Bool) throws {
    guard estimatedItemHeight > 0 else { return }

    let y = CGFloat(index * estimatedItemHeight)

    print("🟣 [HYBRID:scrollToIndex]", index)

    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: y),
      animated: animated
    )
  }

  // MARK: - Layout

  private func updateLayout() {
    print(
      "🔵 [LAYOUT:updateLayout]",
      "itemCount =", itemCount,
      "estimatedItemHeight =", estimatedItemHeight,
      "bounds =", rootView.bounds
    )

    guard itemCount > 0, estimatedItemHeight > 0 else {
      print("🔴 [ABORT:updateLayout] missing data")
      return
    }

    if rootView.bounds.width == 0 {
      print("🟡 [LAYOUT] deferring until bounds exist")
      needsLayoutUpdate = true
      return
    }

    let height = CGFloat(itemCount * estimatedItemHeight)

    rootView.updateContent(height: height)
  }

  // MARK: - Scroll math

  private func handleScroll(offsetY: CGFloat, viewportHeight: CGFloat) {
    guard estimatedItemHeight > 0 else { return }

    let rawStart = Int(offsetY / CGFloat(estimatedItemHeight))
    let rawEnd = Int((offsetY + viewportHeight) / CGFloat(estimatedItemHeight))

    let start = max(rawStart - overscanCount, 0)
    let end = min(
      rawEnd + overscanCount,
      Int(itemCount) - 1
    )

    if start != visibleStart || end != visibleEnd {
      visibleStart = start
      visibleEnd = end

      print("🟣 [HYBRID:visibleRange+overscan]", start, end)

      onVisibleRangeChange?(Double(start), Double(end))

      rootView.updateVisibleCells(
        start: start,
        end: end,
        itemHeight: CGFloat(estimatedItemHeight)
      )
    }
  }

}
