final class LayoutFreezeController {

  private(set) var isFrozen: Bool = false

  func freeze() {
    isFrozen = true
  }

  func unfreeze() {
    isFrozen = false
  }
}
