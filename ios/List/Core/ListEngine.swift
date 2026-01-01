import UIKit

final class ListEngine {

  var itemCount: Int = 0 {
    didSet { layout.itemCount = itemCount }
  }

  var estimatedItemHeight: CGFloat = 0 {
    didSet { layout.estimatedItemHeight = estimatedItemHeight }
  }

  var onVisibleRangeChange: ((Int, Int) -> Void)?

  let rootView = ListRootView()
  var view: UIView { rootView }

  private let layout = ListLayoutEngine()
  private let scroll = ListScrollHandler()

  init() {

    scroll.layout = layout

    rootView.onLayoutReady = { [weak self] in
      guard let self else { return }

      self.layout.build()
      self.rootView.setContentHeight(self.layout.totalHeight)
      self.scroll.reset()

      // ✅ GUARANTEED FIRST MOUNT
      self.scroll.handleScroll(
        offsetY: 0,
        viewportHeight: self.rootView.bounds.height
      )
    }

    rootView.onScroll = { [weak self] offsetY, height in
      self?.scroll.handleScroll(
        offsetY: offsetY,
        viewportHeight: height
      )
    }

    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }

      let delta = self.layout.updateHeight(at: index, height: height)
      self.rootView.setContentHeight(self.layout.totalHeight)

      if self.layout.offset(at: index) < self.rootView.scrollView.contentOffset.y {
        self.rootView.scrollView.contentOffset.y += delta
      }

      self.scroll.reset()
    }

    scroll.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }
      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layout
      )
      self.onVisibleRangeChange?(start, end)
    }
  }

  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layout.count else { return }
    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: layout.offset(at: index)),
      animated: animated
    )
  }
}
