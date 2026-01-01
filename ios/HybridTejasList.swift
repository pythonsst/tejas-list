import UIKit
import NitroModules

final class HybridTejasList: HybridTejasListSpec {

  private let overscan = 5

  let rootView = TejasListRootView()
  var view: UIView { rootView }

  var itemCount: Double = 0 { didSet { layoutIfNeeded() } }
  var estimatedItemHeight: Double = 0 { didSet { layoutIfNeeded() } }

  var onVisibleRangeChange: ((Double, Double) -> Void)?

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

  private func layoutIfNeeded(force: Bool = false) {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    if rootView.bounds.height == 0 {
      needsLayout = true
      return
    }

    if force || needsLayout {
      needsLayout = false

      let totalHeight =
        CGFloat(itemCount) * CGFloat(estimatedItemHeight)

      rootView.setContentHeight(totalHeight)

      // 🔥 FORCE INITIAL MOUNT
      handleScroll(
        offsetY: rootView.scrollView.contentOffset.y,
        viewportHeight: rootView.bounds.height
      )
    }
  }

  private func handleScroll(offsetY: CGFloat, viewportHeight: CGFloat) {
    let itemHeight = CGFloat(estimatedItemHeight)
    let maxIndex = Int(itemCount) - 1

    let first =
      max(Int(offsetY / itemHeight) - overscan, 0)

    let last =
      min(
        Int((offsetY + viewportHeight) / itemHeight) + overscan,
        maxIndex
      )

    guard first != lastStart || last != lastEnd else { return }

    lastStart = first
    lastEnd = last

    rootView.mountCells(
      start: first,
      end: last,
      itemHeight: itemHeight
    )

    onVisibleRangeChange?(Double(first), Double(last))
  }

  func scrollToIndex(index: Double, animated: Bool) throws {
    let y = CGFloat(index) * CGFloat(estimatedItemHeight)
    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: y),
      animated: animated
    )
  }
}
