import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState = CZDownloadedListState()
  
  var body: some View {
    List(listState.downloads, id: \.diffId) {
      CZDownloadingCell(download: $0)
    }
  }
}
