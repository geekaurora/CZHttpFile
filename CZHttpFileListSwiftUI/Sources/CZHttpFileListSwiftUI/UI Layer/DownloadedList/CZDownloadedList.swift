import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState = CZDownloadedListState()
  @State
  var currentCacheSize = 0
  
  func refresh() {
    self.currentCacheSize = CZHttpFileManager.shared.cache.currentCacheSize
  }
  
  var body: some View {
    let cacheInfo = "currentCacheSize = \(currentCacheSize.sizeString) \nmaxCacheSize = \(CZHttpFileManager.shared.cache.maxCacheSize.sizeString)"
    
    VStack {
      Text(cacheInfo)
      Spacer(minLength: 10)
      
      Button("Clear All Cache") {
        CZHttpFileManager.shared.cache.clearCache() {
          self.refresh()
          CZAlertManager.showAlert(message: "Cleared all cache!")
        }
      }
      
      List(listState.downloads, id: \.diffId) {
        CZDownloadingCell(download: $0)
      }
    }.onAppear {
      refresh()
    }
  }
}
