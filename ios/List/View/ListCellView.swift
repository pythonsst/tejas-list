import UIKit

/// Native list cell.
/// Measures itself only when bound index matches.
final class ListCellView: UIView {

  private let label = UILabel()

  private(set) var index: Int = -1
  private var boundIndex: Int = -1

  var onSizeMeasured: ((CGFloat) -> Void)?

  private var lastMeasuredSize: CGFloat = -1
  private var cachedIntrinsicSize: CGSize = .zero
  private var scrollAxis: ScrollAxis = .vertical

  override init(frame: CGRect) {
    super.init(frame: frame)

    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16)
    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  func setScrollAxis(_ axis: ScrollAxis) {
    scrollAxis = axis
    lastMeasuredSize = -1
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds

    let measured =
      scrollAxis == .horizontal
        ? cachedIntrinsicSize.width + 16
        : cachedIntrinsicSize.height + 16

    guard measured != lastMeasuredSize else { return }
    guard index == boundIndex else { return } // 🔒 REQUIRED

    lastMeasuredSize = measured
    onSizeMeasured?(measured)
  }

  func bind(index: Int) {
    self.index = index
    self.boundIndex = index
    label.text = "Row \(index)"
    cachedIntrinsicSize = label.intrinsicContentSize
    lastMeasuredSize = -1
    setNeedsLayout()
  }

  func prepareForReuse() {
    index = -1
    boundIndex = -1
    label.text = nil
    cachedIntrinsicSize = .zero
    onSizeMeasured = nil
    lastMeasuredSize = -1
  }
}
