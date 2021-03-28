import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

private var kvoContext: UInt8 = 0

class CZDownloadingListState: NSObject, ObservableObject {
  @Published
  var downloads: [Download] = []
  
  override init() {
    super.init()    
    CZHttpFileManager.shared.downloadingObserverManager.addObserver(self)
  }
}

// MARK: - CZDownloadingObserverProtocol

extension CZDownloadingListState: CZDownloadingObserverProtocol {
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL]) {
    dbgPrint("\(type(of: self)).downloadingURLsDidUpdate() - downloadingURLs = \n\(downloadingURLs)")
    
    var downloads: [Download] = []
    for (id, url) in downloadingURLs.enumerated() {
      downloads.append(Download(id: id, url: url))
    }
    self.downloads = downloads
  }
}
