import SwiftUI
import SwiftUIKit
import CZUtils
import CZHttpFile

public struct CZDownload: ListDiffCodable {
  public let url: URL
  public init(url: URL) {
    self.url = url
  }
}
