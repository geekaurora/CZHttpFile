import Foundation

public enum CZHttpFileDownloadState: String, CustomStringConvertible {
  case none
  case downloading
  case downloaded
  
  public var description: String {
    return rawValue
  }
}
