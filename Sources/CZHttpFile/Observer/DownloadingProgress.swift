import UIKit
import CZUtils
import CZNetworking

/**
 Struct that represents downloading progress information.
 */
public struct DownloadingProgress {
  public let url: URL
  public var progress: Double
  public init(url: URL, progress: Double) {
    self.url = url
    self.progress = progress
  }
}
