import SwiftUI
import CZUtils
import CZHttpFile

class CZDownloadingListState: NSObject, ObservableObject {
  @Published
  var downloads: [CZDownload] = []
  
  override init() {
    super.init()    
    CZHttpFileManager.shared.downloadingObserverManager.addObserver(self)
  }
}

// MARK: - CZDownloadingObserverProtocol

extension CZDownloadingListState: CZDownloadingObserverProtocol {
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL]) {
    dbgPrint("\(type(of: self)).downloadingURLsDidUpdate() - downloadingURLs = \n\(downloadingURLs)")
    
    var downloads: [CZDownload] = []
    for (id, url) in downloadingURLs.enumerated() {
      downloads.append(CZDownload(url: url))
    }
    self.downloads = downloads
  }
}
