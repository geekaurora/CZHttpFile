import SwiftUI
import CZUtils
import CZHttpFile

struct SingleDownloadView: View {
  @State private var downloadAmount = 0.0
  
  let url = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!
  
  var cacheFileUrl: URL? {
    let cacheFileInfo = CZHttpFileManager.shared.cache.getCacheFileInfo(forURL: url)
    return cacheFileInfo.fileURL
  }
  
  var body: some View {
    VStack {
      ProgressView(value: downloadAmount, total: 1)
      
      Button("Download") {
        CZHttpFileManager.shared.downloadFile(
          url: url,
          progress: { (currSize: Int64, totalSize: Int64, downloadURL: URL) in
            self.downloadAmount = Double(currSize) / Double(totalSize)
            dbgPrint("Downloaded url - downloadAmount = \(downloadAmount), currSize = \(currSize), totalSize = \(totalSize)")

          }) { (data: Data?, error: Error?, fromCache: Bool) in
          dbgPrint("Downloaded url - \(url)")

        }
        
      }
      
    }
  }
}
