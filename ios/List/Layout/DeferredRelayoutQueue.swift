final class DeferredRelayoutQueue {

  private var dirtyStartIndex: Int?
  private var pending = false

  func recordDirty(from index: Int) {
    if let existing = dirtyStartIndex {
      dirtyStartIndex = min(existing, index)
    } else {
      dirtyStartIndex = index
    }
    pending = true
  }

  func consume() -> Int? {
    guard pending else { return nil }
    pending = false
    let value = dirtyStartIndex
    dirtyStartIndex = nil
    return value
  }

  func reset() {
    dirtyStartIndex = nil
    pending = false
  }
}
