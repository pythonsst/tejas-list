/// Enforces a hard limit on mounted views.
final class MountLimiter {

  private let maxMounted: Int

  init(maxMounted: Int) {
    self.maxMounted = maxMounted
  }

  func assertWithinLimit(
    visible: Int,
    prefetched: Int
  ) {
    #if DEBUG
    assert(
      visible + prefetched <= maxMounted,
      "❌ Mounted views exceeded limit"
    )
    #endif
  }
}
