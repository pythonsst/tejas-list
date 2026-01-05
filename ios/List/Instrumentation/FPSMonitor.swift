import QuartzCore

final class FPSMonitor {

  private var displayLink: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frameCount = 0

  var onFPS: ((Double) -> Void)?

  func start() {
    stop()
    lastTimestamp = 0
    frameCount = 0

    displayLink = CADisplayLink(
      target: self,
      selector: #selector(tick)
    )
    displayLink?.add(to: .main, forMode: .common)
  }

  func stop() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func tick(link: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = link.timestamp
      return
    }

    frameCount += 1
    let delta = link.timestamp - lastTimestamp

    if delta >= 1 {
      let fps = Double(frameCount) / delta
      onFPS?(fps)

      frameCount = 0
      lastTimestamp = link.timestamp
    }
  }
}
