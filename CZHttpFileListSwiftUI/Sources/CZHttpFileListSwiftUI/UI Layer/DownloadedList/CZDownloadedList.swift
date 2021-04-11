import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState = CZDownloadedListState()
  
  var body: some View {
    let cacheInfo = "currentCacheSize = \(CZHttpFileManager.shared.cache.currentCacheSize.sizeString) \nmaxCacheSize = \(CZHttpFileManager.shared.cache.maxCacheSize.sizeString)"
    
    VStack {
      Text(cacheInfo)
      Spacer(minLength: 10)
      
      Button("Clear All Cache") {
        CZHttpFileManager.shared.cache.clearCache() {
          CZAlertManager.showAlert(message: "Cleared all cache!")
        }
      }
      
      List(listState.downloads, id: \.diffId) {
        CZDownloadingCell(download: $0)
      }
    }
  }
}
