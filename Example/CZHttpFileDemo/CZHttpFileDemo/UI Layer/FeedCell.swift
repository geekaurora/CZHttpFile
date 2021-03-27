import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct FeedCell: View {
  @State private var downloadAmount = 0.0
  
  let feed: Feed
  
  var body: some View {
    VStack {
      ProgressView(feed.url.absoluteString, value: downloadAmount, total: 1)
      
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
    .onAppear {
      let cachedFileURL =  CZHttpFileManager.shared.cachedFileURL(forURL: feed.url)
      // dbgPrint("cachedFileURL = \(cachedFileURL)")
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
