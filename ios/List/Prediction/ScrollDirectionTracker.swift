import CoreGraphics

enum ScrollDirection {
  case forward
  case backward
  case none
}

final class ScrollDirectionTracker {

  private var lastOffset: CGFloat = 0
  private(set) var direction: ScrollDirection = .none

  func update(offset: CGFloat) {
    if offset > lastOffset {
      direction = .forward
    } else if offset < lastOffset {
      direction = .backward
    }
    lastOffset = offset
  }

  func reset() {
    lastOffset = 0
    direction = .none
  }
}
