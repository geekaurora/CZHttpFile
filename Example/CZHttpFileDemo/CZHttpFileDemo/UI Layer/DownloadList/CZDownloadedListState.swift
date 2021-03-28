import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

private var kvoContext: UInt8 = 0

class CZDownloadedListState: NSObject, ObservableObject {
  @Published
  var downloads: [Download] = []
  
  override init() {
    super.init()    
    CZHttpFileManager.shared.downloadedObserverManager.addObserver(self)
  }
}

// MARK: - CZDownloadedObserverProtocol

extension CZDownloadedListState: CZDownloadedObserverProtocol {
  func downloadedURLsDidUpdate(_ downloadedURLs: [URL]) {
    dbgPrint("\(type(of: self)).downloadedURLsDidUpdate() - downloadedURLs = \n\(downloadedURLs)")
    
    var downloads: [Download] = []
    for (id, url) in downloadedURLs.enumerated() {
      downloads.append(Download(id: id, url: url))
    }
    self.downloads = downloads
  }
}
