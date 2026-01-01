import UIKit

final class TejasListCellView: UIView {

  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)

    label.textAlignment = .center
    label.font = .systemFont(ofSize: 16, weight: .medium)
    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds
  }

  func bind(index: Int) {
    label.text = "Row \(index)"
    backgroundColor =
      index.isMultiple(of: 2)
      ? UIColor.systemBlue.withAlphaComponent(0.2)
      : UIColor.systemGreen.withAlphaComponent(0.2)
  }

  func prepareForReuse() {
    label.text = nil
    backgroundColor = .clear
  }
}
