import UIKit

final class TejasListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  let contentView = UIView()

  // Callbacks to Hybrid layer
  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayout: (() -> Void)?

  // Cell management
  private var visibleCells: [Int: TejasListCellView] = [:]
  private var reusePool: [TejasListCellView] = []

  override init(frame: CGRect) {
    super.init(frame: frame)

    print("🟢 [ROOT:init] frame =", frame)

    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = true
    scrollView.delegate = self

    // Debug colors (keep for now)
    backgroundColor = .systemBlue.withAlphaComponent(0.05)
    scrollView.backgroundColor = .systemYellow.withAlphaComponent(0.15)
    contentView.backgroundColor = .systemRed.withAlphaComponent(0.10)

    addSubview(scrollView)
    scrollView.addSubview(contentView)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    print("🟢 [ROOT:layoutSubviews] bounds =", bounds)

    scrollView.frame = bounds

    if bounds.width > 0 {
      onLayout?()
    }
  }

  func updateContent(height: CGFloat) {
    print("🔵 [LAYOUT:updateContent] height =", height)

    contentView.frame = CGRect(
      x: 0,
      y: 0,
      width: bounds.width,
      height: height
    )

    scrollView.contentSize = contentView.bounds.size

    print(
      "🔵 [LAYOUT:updateContent]",
      "contentView.frame =", contentView.frame,
      "contentSize =", scrollView.contentSize
    )
  }

  // MARK: - Cell Virtualization

  func updateVisibleCells(
    start: Int,
    end: Int,
    itemHeight: CGFloat
  ) {
    print("🟣 [ROOT:updateVisibleCells]", start, end)

    // Recycle cells that left viewport
    for (index, cell) in visibleCells {
      if index < start || index > end {
        cell.prepareForReuse()
        cell.removeFromSuperview()
        reusePool.append(cell)
        visibleCells.removeValue(forKey: index)

        print("🔴 [CELL:recycle]", index)
      }
    }

    // Mount missing cells
    for index in start...end {
      if visibleCells[index] == nil {
        let cell = reusePool.popLast() ?? TejasListCellView()

        cell.bind(index: index)
        cell.frame = CGRect(
          x: 0,
          y: CGFloat(index) * itemHeight,
          width: bounds.width,
          height: itemHeight
        )

        contentView.addSubview(cell)
        visibleCells[index] = cell

        print("🟢 [CELL:mount]", index)
      }
    }
  }

  // MARK: - UIScrollViewDelegate

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offsetY = scrollView.contentOffset.y
    let viewportHeight = scrollView.bounds.height

    print(
      "🟠 [SCROLL]",
      "offsetY =", offsetY,
      "viewportHeight =", viewportHeight
    )

    onScroll?(offsetY, viewportHeight)
  }
}
