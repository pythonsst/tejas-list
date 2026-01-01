import UIKit

final class TejasListRootView: UIView, UIScrollViewDelegate {

  let scrollView = UIScrollView()
  let contentView = UIView()

  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onLayout: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)

    print("🟢 [ROOT:init] frame =", frame)

    scrollView.alwaysBounceVertical = true
    scrollView.showsVerticalScrollIndicator = true

    // DEBUG COLORS (REMOVE LATER)
    backgroundColor = .systemBlue.withAlphaComponent(0.05)
    scrollView.backgroundColor = .systemYellow.withAlphaComponent(0.15)
    contentView.backgroundColor = .systemRed.withAlphaComponent(0.15)

    scrollView.delegate = self
    addSubview(scrollView)
    scrollView.addSubview(contentView)

    print("🟢 [ROOT:init] subviews added")
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    print("🟢 [ROOT:didMoveToSuperview] superview =", String(describing: superview))
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    print("🟢 [ROOT:didMoveToWindow] window =", String(describing: window))
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    print(
      "🟢 [ROOT:layoutSubviews]",
      "bounds =", bounds,
      "scrollView.frame(before) =", scrollView.frame
    )

    scrollView.frame = bounds

    print(
      "🟢 [ROOT:layoutSubviews]",
      "scrollView.frame(after) =", scrollView.frame
    )

    if bounds.width > 0 {
      print("🟢 [ROOT:layoutSubviews] bounds valid → notifying Hybrid")
      onLayout?()
    } else {
      print("🔴 [ROOT:layoutSubviews] bounds.width == 0")
    }
  }

  func updateContent(height: CGFloat) {
    print(
      "🔵 [LAYOUT:updateContent]",
      "height =", height,
      "bounds.width =", bounds.width
    )

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
