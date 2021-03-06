import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer
import CZHttpFileListSwiftUI

struct MultiDownloadsView: View {
//    let downloads: [Download] = [
//      .init(id: 0, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 1, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 2, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 3, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 4, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 5, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 6, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      .init(id: 7, url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
//      ]
    
  let downloads: [CZDownload] = [
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter02.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter03.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter04.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter05.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter06.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter07.m4a")!),
  ]
  
  var body: some View {
    List(downloads, id: \.diffId) {
      DownloadCell(download: $0)
    }
  }
}
