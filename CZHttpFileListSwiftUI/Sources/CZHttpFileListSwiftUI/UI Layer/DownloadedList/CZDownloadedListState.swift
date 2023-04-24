import SwiftUI
import CZUtils
import CZHttpFile

class CZDownloadedListState: NSObject, ObservableObject {
  @Published
  var downloads: [CZDownload] = []
  
  @Published
  var currentCacheSize = CZHttpFileManager.shared.cache.currentCacheSize
  
  override init() {
    super.init()
    
    CZHttpFileManager.shared.downloadedObserverManager?.addObserver(self)
  }
  
  func refreshCurrentCacheSize() {
    self.currentCacheSize = CZHttpFileManager.shared.cache.currentCacheSize
  }
}

// MARK: - CZDownloadedObserverProtocol

extension CZDownloadedListState: CZDownloadedObserverProtocol {
  func downloadedURLsDidUpdate(_ downloadedURLs: [URL]) {
    dbgPrint("\(type(of: self)).\(#function) - downloadedURLs = \n\(downloadedURLs)")
    updateWithDownloadedURLs(downloadedURLs)
  }
}

// MARK: - Private methods

extension CZDownloadedListState {
  func updateWithDownloadedURLs(_ downloadedURLs: [URL]) {
    // dbgPrint("\(type(of: self)).\(#function) - downloadedURLs = \n\(downloadedURLs)")
    self.downloads = downloadedURLs.map { CZDownload(url: $0)  }
  }
}
