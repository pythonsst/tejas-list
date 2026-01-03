import UIKit

final class NativeScrollController {

  weak var scrollView: UIScrollView?
  weak var layout: ListLayoutEngine?

  func scrollToIndex(_ index: Int, animated: Bool) {
    guard let scrollView, let layout else { return }
    guard index >= 0, index < layout.count else { return }

    let offset = layout.offset(at: index)
    scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
  }
}
