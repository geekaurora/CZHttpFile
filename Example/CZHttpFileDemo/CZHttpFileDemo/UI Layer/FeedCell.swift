import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct FeedCell: View {
  @State private var downloadAmount = 0.0
  
  let feed: Feed
  
  var body: some View {
    VStack {
      ProgressView(value: downloadAmount, total: 1)
      
      Button("Download") {
        CZHttpFileManager.shared.downloadFile(
          url: feed.url,
          progress: { (currSize: Int64, totalSize: Int64, downloadURL: URL) in
            self.downloadAmount = Double(currSize) / Double(totalSize)
            dbgPrint("Downloaded url - downloadAmount = \(downloadAmount), currSize = \(currSize), totalSize = \(totalSize)")

          }) { (data: Data?, error: Error?, fromCache: Bool) in
          dbgPrint("Downloaded url - \(feed.url)")

        }
        
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
