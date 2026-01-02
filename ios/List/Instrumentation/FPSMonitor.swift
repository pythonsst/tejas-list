import QuartzCore

/// Lightweight UI-thread FPS monitor.
final class FPSMonitor {

  private var link: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var frames = 0

  /// Called once per second with current FPS.
  var onUpdate: ((Int) -> Void)?

  func start() {
    stop()
    lastTimestamp = 0
    frames = 0

    let link = CADisplayLink(target: self, selector: #selector(tick))
    link.add(to: .main, forMode: .common)
    self.link = link
  }

  func stop() {
    link?.invalidate()
    link = nil
  }

  @objc private func tick(_ link: CADisplayLink) {
    if lastTimestamp == 0 {
      lastTimestamp = link.timestamp
      return
    }

    frames += 1
    let delta = link.timestamp - lastTimestamp

    if delta >= 1 {
      let fps = Int(round(Double(frames) / delta))
      onUpdate?(fps)

      frames = 0
      lastTimestamp = link.timestamp
    }
  }
}
