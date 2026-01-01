import UIKit

final class TejasListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  private let contentView = UIView()

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayoutReady: (() -> Void)?

  private var visibleCells: [Int: TejasListCellView] = [:]
  private var reusePool: [TejasListCellView] = []
  private var didLayout = false

  override init(frame: CGRect) {
    super.init(frame: frame)

    scrollView.delegate = self
    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = true
    scrollView.contentInsetAdjustmentBehavior = .never

    addSubview(scrollView)
    scrollView.addSubview(contentView)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    scrollView.frame = bounds

    if !didLayout && bounds.height > 0 {
      didLayout = true
      onLayoutReady?()
    }
  }

  func setContentHeight(_ height: CGFloat) {
    contentView.frame = CGRect(
      x: 0,
      y: 0,
      width: bounds.width,
      height: height
    )
    scrollView.contentSize = contentView.bounds.size
  }

  // MARK: Variable-height mounting

  func mountCells(
    start: Int,
    end: Int,
    offsets: [CGFloat],
    heights: [CGFloat]
  ) {
    guard start <= end else { return }

    // Recycle
    for (index, cell) in visibleCells where index < start || index > end {
      cell.prepareForReuse()
      cell.removeFromSuperview()
      reusePool.append(cell)
      visibleCells.removeValue(forKey: index)
    }

    // Mount
    for index in start...end where visibleCells[index] == nil {
      let cell = reusePool.popLast() ?? TejasListCellView()
      cell.bind(index: index)

      cell.frame = CGRect(
        x: 0,
        y: offsets[index],
        width: bounds.width,
        height: heights[index]
      )

      contentView.addSubview(cell)
      visibleCells[index] = cell
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    onScroll?(
      scrollView.contentOffset.y,
      scrollView.bounds.height
    )
  }
}
