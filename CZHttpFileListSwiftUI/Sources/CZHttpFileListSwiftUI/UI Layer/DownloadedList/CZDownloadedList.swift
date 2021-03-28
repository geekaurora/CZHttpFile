import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadedList: View {
  @ObservedObject
  var listState = CZDownloadedListState()
  
//  let downloads: [Download] = [
//    .init(id: 0, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//    .init(id: 1, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter02.m4a")!),
//    .init(id: 2, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter03.m4a")!),
//    .init(id: 3, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter04.m4a")!),
//    .init(id: 4, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter05.m4a")!),
//    .init(id: 5, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter06.m4a")!),
//    .init(id: 6, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter07.m4a")!),
//  ]
  
  var body: some View {
    List(listState.downloads, id: \.diffId) {
      CZDownloadingCell(download: $0)
    }
    .onAppear() {      
    }
  }
}
