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
  func downloadingProgressDidUpdate(_ downloadingProgressList: [DownloadingProgress]) {
    dbgPrintWithFunc(self, "downloadingProgressList = \(downloadingProgressList)")
    
    self.downloads = downloadingProgressList.map { CZDownload(url: $0.url, progress: $0.progress)  }
    
  }
  
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL]) {
    dbgPrint("\(type(of: self)).downloadingURLsDidUpdate() - downloadingURLs = \n\(downloadingURLs)")
    self.downloads = downloadingURLs.map { CZDownload(url: $0)  }
  }
}
