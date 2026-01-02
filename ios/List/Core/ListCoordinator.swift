import UIKit

/// Native orchestrator for layout, scrolling, and mounting.
final class ListCoordinator {

  let rootView = ListRootView()
  var onVisibleRangeChange: ((Int, Int) -> Void)?

  private let layoutEngine = ListLayoutEngine()
  private let scrollHandler = ListScrollHandler()

  private var scrollAxis: ScrollAxis = .vertical
  private var needsLayoutBuild = true

  init() {
    scrollHandler.layout = layoutEngine

    rootView.onLayoutReady = { [weak self] in
      self?.rebuildLayoutAndMount()
    }

    rootView.onScroll = { [weak self] offset, viewport in
      self?.scrollHandler.handleScroll(
        scrollOffset: offset,
        viewportSize: viewport
      )
    }

    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }
      self.rootView.mountCells(start: start, end: end, layout: self.layoutEngine)
      self.onVisibleRangeChange?(start, end)
    }

    // 🔥 FIXED MEASUREMENT PIPELINE
    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }

      self.layoutEngine.markHeightDirty(at: index, height: height)
      self.layoutEngine.commit()

      self.rootView.setContentSize(
        self.scrollAxis == .horizontal
          ? CGSize(
              width: self.layoutEngine.totalHeight,
              height: self.rootView.bounds.height
            )
          : CGSize(
              width: self.rootView.bounds.width,
              height: self.layoutEngine.totalHeight
            )
      )

      self.rootView.relayoutVisibleCells(
        from: index,
        layout: self.layoutEngine
      )

      let scrollOffset =
        self.scrollAxis == .horizontal
          ? self.rootView.scrollView.contentOffset.x
          : self.rootView.scrollView.contentOffset.y

      let viewport =
        self.scrollAxis == .horizontal
          ? self.rootView.bounds.width
          : self.rootView.bounds.height

      self.scrollHandler.reset()
      self.scrollHandler.handleScroll(
        scrollOffset: scrollOffset,
        viewportSize: viewport
      )
    }
  }

  func setScrollDirection(_ direction: ScrollDirection?) {
    scrollAxis = direction == .horizontal ? .horizontal : .vertical
    scrollHandler.scrollAxis = scrollAxis
    rootView.setScrollAxis(scrollAxis)
    needsLayoutBuild = true
    reload()
  }

  func reload() {
    scrollHandler.reset()
    rebuildLayoutAndMount()
  }

  func setItemCount(_ count: Int) {
    layoutEngine.itemCount = count
    needsLayoutBuild = true
  }

  func setEstimatedItemHeight(_ height: CGFloat) {
    layoutEngine.estimatedItemHeight = height
    needsLayoutBuild = true
  }

  func scrollToIndex(_ index: Int, animated: Bool) {
    guard index >= 0, index < layoutEngine.count else { return }

    let offset = layoutEngine.offset(at: index)
    rootView.scrollView.setContentOffset(
      scrollAxis == .horizontal
        ? CGPoint(x: offset, y: 0)
        : CGPoint(x: 0, y: offset),
      animated: animated
    )
  }

  private func rebuildLayoutAndMount() {
    guard
      needsLayoutBuild,
      layoutEngine.itemCount > 0,
      layoutEngine.estimatedItemHeight > 0,
      rootView.bounds.width > 0,
      rootView.bounds.height > 0
    else { return }

    needsLayoutBuild = false
    layoutEngine.build()

    rootView.setContentSize(
      scrollAxis == .horizontal
        ? CGSize(
            width: layoutEngine.totalHeight,
            height: rootView.bounds.height
          )
        : CGSize(
            width: rootView.bounds.width,
            height: layoutEngine.totalHeight
          )
    )

    scrollHandler.reset()

    let offset =
      scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y

    let viewport =
      scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height

    scrollHandler.handleScroll(
      scrollOffset: offset,
      viewportSize: viewport
    )
  }
}
