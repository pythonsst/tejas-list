import Foundation

enum ListInvariants {

  /// Hard safety cap for mounted views.
  /// Visible + Prefetched must NEVER exceed this.
  static let maxMountedViews = 160

  static func assertMaxMounted(
    visible: Int,
    prefetched: Int
  ) {
    #if DEBUG
    let total = visible + prefetched
    assert(
      total <= maxMountedViews,
      """
      ❌ Max-mounted invariant violated
      visible=\(visible)
      prefetched=\(prefetched)
      total=\(total)
      cap=\(maxMountedViews)
      """
    )
    #endif
  }

  static func assertRange(
    start: Int,
    end: Int,
    count: Int
  ) {
    #if DEBUG
    assert(start >= 0 && end < count && start <= end)
    #endif
  }

  static func assertMainThread() {
    #if DEBUG
    assert(Thread.isMainThread)
    #endif
  }
}
