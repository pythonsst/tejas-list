import UIKit

final class CellSnapshotCache {

  private var cache: [Int: UIView] = [:]

  func snapshot(cell: UIView, index: Int) {
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, true, 0)
    cell.layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    if let image {
      let view = UIImageView(image: image)
      view.frame = cell.frame
      cache[index] = view
    }
  }

  func snapshotView(for index: Int) -> UIView? {
    cache[index]
  }

  func reset() {
    cache.removeAll()
  }
}
