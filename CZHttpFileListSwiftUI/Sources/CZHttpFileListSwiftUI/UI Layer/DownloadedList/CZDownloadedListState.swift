import SwiftUI
import CZUtils
import CZHttpFile

class CZDownloadedListState: NSObject, ObservableObject {
  @Published
  var downloads: [CZDownload] = []
  
  @Published
  var currentCacheSize: Int
  
  private let cache: CZBaseHttpFileCacheProtocol
  
  init(cache: CZBaseHttpFileCacheProtocol) {
    self.cache = cache
    self.currentCacheSize = cache.currentCacheSize
    self.downloads = cache.downloadedURLs.map { CZDownload(url: $0) }
    super.init()
    
    CZHttpFileManager.shared.downloadedObserverManager?.addObserver(self)
  }
  
  func refresh() {
    self.currentCacheSize = cache.currentCacheSize
    updateWithDownloadedURLs()
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
  func updateWithDownloadedURLs() {
    updateWithDownloadedURLs(cache.downloadedURLs)
  }

  func updateWithDownloadedURLs(_ downloadedURLs: [URL]) {
    // dbgPrint("\(type(of: self)).\(#function) - downloadedURLs = \n\(downloadedURLs)")
    self.downloads = downloadedURLs.map { CZDownload(url: $0)  }
  }
}
