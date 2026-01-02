import UIKit

/// Native orchestrator for layout, scrolling, and cell mounting.
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

    rootView.onScroll = { [weak self] scrollOffset, viewportSize in
      self?.scrollHandler.handleScroll(
        scrollOffset: scrollOffset,
        viewportSize: viewportSize
      )
    }

    scrollHandler.onVisibleRangeChange = { [weak self] start, end in
      guard let self else { return }

      self.rootView.mountCells(
        start: start,
        end: end,
        layout: self.layoutEngine
      )

      self.onVisibleRangeChange?(start, end)
    }

    rootView.onCellHeightChange = { [weak self] index, height in
      guard let self else { return }

      let delta = self.layoutEngine.updateHeight(
        at: index,
        height: height
      )

      guard delta != 0 else { return }

      let currentOffset =
        self.scrollAxis == .horizontal
          ? self.rootView.scrollView.contentOffset.x
          : self.rootView.scrollView.contentOffset.y

      if self.layoutEngine.offset(at: index) < currentOffset {
        if self.scrollAxis == .horizontal {
          self.rootView.scrollView.contentOffset.x += delta
        } else {
          self.rootView.scrollView.contentOffset.y += delta
        }
      }

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

      self.scrollHandler.reset()
    }
  }

  // MARK: - Public API

  func setScrollDirection(_ direction: ScrollDirection?) {
    scrollAxis = (direction == .horizontal) ? .horizontal : .vertical

    scrollHandler.scrollAxis = scrollAxis
    rootView.setScrollAxis(scrollAxis)

    needsLayoutBuild = true   // 🔴 REQUIRED
    scrollHandler.reset()
    rebuildLayoutAndMount()
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

    let targetOffset = layoutEngine.offset(at: index)

    if scrollAxis == .horizontal {
      rootView.scrollView.setContentOffset(
        CGPoint(x: targetOffset, y: 0),
        animated: animated
      )
    } else {
      rootView.scrollView.setContentOffset(
        CGPoint(x: 0, y: targetOffset),
        animated: animated
      )
    }
  }

  // MARK: - Internal

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

    let viewportSize =
      scrollAxis == .horizontal
        ? rootView.bounds.width
        : rootView.bounds.height

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

    let scrollOffset =
      scrollAxis == .horizontal
        ? rootView.scrollView.contentOffset.x
        : rootView.scrollView.contentOffset.y

    scrollHandler.handleScroll(
      scrollOffset: scrollOffset,
      viewportSize: viewportSize
    )
  }

}
