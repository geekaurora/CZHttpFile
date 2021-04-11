import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState = CZDownloadedListState()
  
  var body: some View {
    let cacheInfo = "currentCacheSize = \(CZHttpFileManager.shared.cache.currentCacheSize) \nmaxCacheSize = \(CZHttpFileManager.shared.cache.maxCacheSize)"
    
    VStack {
      Text(cacheInfo)

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
