import SwiftUI
import SwiftUIKit
import CZUtils
import CZHttpFile

public struct CZDownload: ListDiffCodable {
  public let url: URL
  public let progress: Double
  public init(url: URL, progress: Double = 0) {
    self.url = url
    self.progress = progress
  }
}
