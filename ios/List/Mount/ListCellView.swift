import UIKit

/// Native list cell.
/// Measures itself safely and deterministically.
final class ListCellView: UIView {

  private let label = UILabel()

  // MARK: - Identity

  private(set) var index: Int = -1
  private var boundIndex: Int = -1

  // MARK: - Callbacks

  var onSizeMeasured: ((CGFloat) -> Void)?

  // MARK: - Measurement state

  private var lastMeasuredSize: CGFloat = -1
  private var cachedMeasuredSize: CGFloat = 0
  private var scrollAxis: ScrollAxis = .vertical

  // MARK: - Init

  override init(frame: CGRect) {
    super.init(frame: frame)

    clipsToBounds = true

    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16)

    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  // MARK: - Axis

  func setScrollAxis(_ axis: ScrollAxis) {
    scrollAxis = axis
    lastMeasuredSize = -1
    setNeedsLayout()
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()

    label.frame = bounds

    // Width-aware measurement (critical for multiline)
    let measured: CGFloat
    if scrollAxis == .horizontal {
      let size = label.sizeThatFits(
        CGSize(width: .greatestFiniteMagnitude, height: bounds.height)
      )
      measured = size.width + 16
    } else {
      let size = label.sizeThatFits(
        CGSize(width: bounds.width, height: .greatestFiniteMagnitude)
      )
      measured = size.height + 16
    }

    // No change → no callback
    guard measured != lastMeasuredSize else { return }

    // Reuse safety
    guard index == boundIndex else { return }

    lastMeasuredSize = measured
    cachedMeasuredSize = measured

    onSizeMeasured?(measured)
  }

  // MARK: - Binding

  func bind(index: Int) {
    self.index = index
    self.boundIndex = index

    label.text = "Row \(index)"

    lastMeasuredSize = -1
    cachedMeasuredSize = 0

    setNeedsLayout()
  }

  // MARK: - Reuse

  func prepareForReuse() {
    index = -1
    boundIndex = -1

    label.text = nil
    cachedMeasuredSize = 0
    lastMeasuredSize = -1

    onSizeMeasured = nil
  }
}
