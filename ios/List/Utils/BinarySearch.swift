import Foundation

enum BinarySearch {
  static func find(_ array: [CGFloat], _ value: CGFloat) -> Int {
    var low = 0
    var high = array.count - 1
    while low <= high {
      let mid = (low + high) / 2
      if array[mid] < value {
        low = mid + 1
      } else {
        high = mid - 1
      }
    }
    return max(0, low - 1)
  }
}
