enum FastScrollPolicy {
  case normal
  case aggressive
}

struct FastScrollRules {

  static func shouldFreeze(
    isFastScrolling: Bool,
    policy: FastScrollPolicy
  ) -> Bool {
    switch policy {
    case .normal:
      return false

    case .aggressive:
      return isFastScrolling
    }
  }
}
