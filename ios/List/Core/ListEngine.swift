import UIKit

final class ListEngine {

  // MARK: - Public API

  var itemCount: Int = 0 {
    didSet { layoutEngine.itemCount = itemCount }
  }

  var estimatedItemHeight: CGFloat = 0 {
    didSet { layoutEngine.estimatedItemHeight = estimatedItemHeight }
  }

  var onVisibleRangeChange: ((Int, Int) -> Void)?

  let rootView = ListRootView()
  var view: UIView { rootView }

  // MARK: - Internals

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()

  // MARK: - Init

  init() {

    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayout()
    }

    rootView.onScroll = { [weak self] offsetY, height in
      self?.scrollHandler.handleScroll(
        offsetY: offsetY,
        viewportHeight: height
      )
    }

    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }
      layoutEngine.updateHeight(at: index, height: height)
      rootView.setContentHeight(layoutEngine.totalHeight)
      scrollHandler.forceUpdate()
    }

    scrollHandler.layoutEngine = layoutEngine

    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }
      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )
      self.onVisibleRangeChange?(start, end)
    }
  }

  // MARK: - Layout

  func rebuildLayout() {
    guard itemCount > 0, estimatedItemHeight > 0 else { return }

    layoutEngine.build()
    rootView.setContentHeight(layoutEngine.totalHeight)
    scrollHandler.forceUpdate()
  }

  // MARK: - Scroll API

  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layoutEngine.count else { return }

    let y = layoutEngine.offset(at: index)
    rootView.scrollView.setContentOffset(
      CGPoint(x: 0, y: y),
      animated: animated
    )
  }
}
