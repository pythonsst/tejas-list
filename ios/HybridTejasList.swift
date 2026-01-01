import UIKit

final class HybridTejasList: HybridTejasListSpec {

  // MARK: - Required by Nitro

  let rootView = TejasListRootView()
  var view: UIView {
    print("🟣 [HYBRID:view] requested")
    return rootView
  }

  // MARK: - Props (ABI)

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

      print("🟣 [HYBRID:onLayout] received")

      if self.needsLayoutUpdate {
        print("🟣 [HYBRID:onLayout] running deferred layout")
        self.needsLayoutUpdate = false
        self.updateLayout()
      }
    }

    rootView.onScroll = { [weak self] offsetY, viewportHeight in
      self?.handleScroll(offsetY: offsetY, viewportHeight: viewportHeight)
    }
  }

  // MARK: - Methods (ABI)

  func scrollToIndex(index: Double, animated: Bool) throws {
    print(
      "🟣 [HYBRID:scrollToIndex]",
      "index =", index,
      "animated =", animated
    )

    guard estimatedItemHeight > 0 else {
      print("🔴 [HYBRID:scrollToIndex] estimatedItemHeight == 0")
      return
    }

    let y = CGFloat(index * estimatedItemHeight)

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

    guard estimatedItemHeight > 0, itemCount > 0 else {
      print("🔴 [ABORT:updateLayout] missing data")
      return
    }

    if rootView.bounds.width == 0 {
      print("🟡 [LAYOUT:updateLayout] bounds not ready → deferring")
      needsLayoutUpdate = true
      return
    }

    let height = CGFloat(itemCount * estimatedItemHeight)

    print(
      "🔵 [LAYOUT:updateLayout]",
      "computed height =", height
    )

    rootView.updateContent(height: height)
  }

  // MARK: - Scroll Math

  private func handleScroll(offsetY: CGFloat, viewportHeight: CGFloat) {
    guard estimatedItemHeight > 0 else {
      print("🔴 [ABORT:handleScroll] estimatedItemHeight == 0")
      return
    }

    let start = max(Int(offsetY / CGFloat(estimatedItemHeight)), 0)
    let end = min(
      Int((offsetY + viewportHeight) / CGFloat(estimatedItemHeight)),
      Int(itemCount) - 1
    )

    print(
      "🟠 [SCROLL:range]",
      "start =", start,
      "end =", end
    )

    if start != visibleStart || end != visibleEnd {
      visibleStart = start
      visibleEnd = end

      print(
        "🟣 [HYBRID:onVisibleRangeChange]",
        start,
        end
      )

      onVisibleRangeChange?(Double(start), Double(end))
    }
  }
}
