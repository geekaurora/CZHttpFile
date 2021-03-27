import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct MultiDownloadsView: View {  
  let feeds: [Feed] = [
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter02.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter03.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter04.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter05.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter06.m4a")!),
    .init(url: URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter07.m4a")!),
  ]
  
  var body: some View {
    List(feeds, id: \.url) {
      FeedCell(feed: $0)
    }
  }
}
