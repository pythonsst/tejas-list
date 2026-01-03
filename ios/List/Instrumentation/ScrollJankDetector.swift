final class ScrollJankDetector {

  private(set) var isJanky = false

  func updateFPS(_ fps: Int) {
    isJanky = fps < 50
  }

  func reset() {
    isJanky = false
  }
}
