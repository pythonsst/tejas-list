enum Phase2Invariants {

  static func assertMainThread() {
    assert(Thread.isMainThread)
  }

  static func assertNoMutationDuringScroll(_ isScrolling: Bool) {
    assert(!isScrolling, "Mutation during scroll")
  }
} 