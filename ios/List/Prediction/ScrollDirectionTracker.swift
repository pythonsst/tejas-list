final class ScrollDirectionTracker {

  private var lastOffset: CGFloat = 0
  private(set) var motion: ScrollMotion = .none

  func update(offset: CGFloat) {
    if offset > lastOffset {
      motion = .forward
    } else if offset < lastOffset {
      motion = .backward
    }
    lastOffset = offset
  }

  func reset() {
    lastOffset = 0
    motion = .none
  }
}
