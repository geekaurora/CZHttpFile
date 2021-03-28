import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

class CZDownloadedListState: NSObject, ObservableObject {
  @Published
  var downloads: [CZDownload] = []
  
  override init() {
    super.init()    
    CZHttpFileManager.shared.downloadedObserverManager.addObserver(self)
  }
}

// MARK: - CZDownloadedObserverProtocol

extension CZDownloadedListState: CZDownloadedObserverProtocol {
  func downloadedURLsDidUpdate(_ downloadedURLs: [URL]) {
    dbgPrint("\(type(of: self)).downloadedURLsDidUpdate() - downloadedURLs = \n\(downloadedURLs)")
    
    var downloads: [CZDownload] = []
    for (id, url) in downloadedURLs.enumerated() {
      downloads.append(CZDownload(url: url))
    }
    self.downloads = downloads
  }
}
