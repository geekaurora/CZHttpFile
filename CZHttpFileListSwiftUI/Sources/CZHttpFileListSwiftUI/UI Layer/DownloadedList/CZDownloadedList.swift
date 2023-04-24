import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState: CZDownloadedListState
  
  private let cache: CZBaseHttpFileCacheProtocol
  
  public init(cache: CZBaseHttpFileCacheProtocol) {
    self.cache = cache
    self.listState = CZDownloadedListState(cache: cache)
  }
  
  var body: some View {
    let cacheInfo = "currentCacheSize = \(listState.currentCacheSize.sizeString) \nmaxCacheSize = \(CZHttpFileManager.shared.cache.maxCacheSize.sizeString)"
    
    VStack {
      Text(cacheInfo)
      Spacer(minLength: 10)
      
      Button("Clear All Cache") {
        self.cache.clearCache() {
          listState.refreshCurrentCacheSize()
          CZAlertManager.showAlert(message: "Cleared all cache!")
        }
      }
      
//      List(listState.downloads, id: \.diffId) {
//        CZDownloadingCell(download: $0)
//      }
    }
    .onAppear {
      listState.refreshCurrentCacheSize()
    }
  }
}
