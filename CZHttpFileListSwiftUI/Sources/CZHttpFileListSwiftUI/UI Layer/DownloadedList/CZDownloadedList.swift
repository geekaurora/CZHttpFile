import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState = CZDownloadedListState()
  
  var body: some View {
    VStack {
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
