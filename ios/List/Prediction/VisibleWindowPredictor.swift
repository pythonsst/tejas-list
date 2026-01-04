struct PredictedWindow {
  let start: Int
  let end: Int
}

final class VisibleWindowPredictor {

  // 🔑 JANK control hook
  var isEnabled: Bool = true

  func predict(
    currentStart: Int,
    currentEnd: Int,
    itemCount: Int,
    velocity: CGFloat,
    motion: ScrollMotion
  ) -> PredictedWindow? {

    // ❄️ Disabled during jank
    guard isEnabled else { return nil }

    guard abs(velocity) > 1200 else { return nil }
    guard motion != .none else { return nil }

    let lookahead = min(20, max(8, Int(abs(velocity) / 400)))

    switch motion {
    case .forward:
      let start = min(itemCount - 1, currentEnd + 1)
      let end = min(itemCount - 1, currentEnd + lookahead)
      return start <= end ? PredictedWindow(start: start, end: end) : nil

    case .backward:
      let end = max(0, currentStart - 1)
      let start = max(0, currentStart - lookahead)
      return start <= end ? PredictedWindow(start: start, end: end) : nil

    case .none:
      return nil
    }
  }
}
