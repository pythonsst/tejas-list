import UIKit

final class ListCellView: UIView {

  private let label = UILabel()
  private(set) var index: Int = -1

  var onHeightMeasured: ((CGFloat) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)

    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16)

    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds

    let height = label.intrinsicContentSize.height + 16
    onHeightMeasured?(height)
  }

  func bind(index: Int) {
    self.index = index
    label.text = "Row \(index)"
    backgroundColor =
      index.isMultiple(of: 2)
        ? .systemBlue.withAlphaComponent(0.15)
        : .systemGreen.withAlphaComponent(0.15)
  }

  func prepareForReuse() {
    index = -1
    label.text = nil
    onHeightMeasured = nil
  }
}
