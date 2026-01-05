enum CellSizeClass {
  case small
  case medium
  case large

  static func classify(size: CGFloat) -> CellSizeClass {
    switch size {
    case ..<80: return .small
    case ..<200: return .medium
    default: return .large
    }
  }
}
