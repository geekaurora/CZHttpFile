import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct DownloadCell: View {
  @State private var downloadAmount = 0.0
  @State private var downloadState = ""
  
  let feed: Feed
  
  func downloadFile() {
    CZHttpFileManager.shared.downloadFile(
      url: feed.url,
      progress: { (currSize: Int64, totalSize: Int64, downloadURL: URL) in
        self.downloadState = CZHttpFileManager.shared.downloadState(forURL: feed.url).rawValue
        self.downloadAmount = Double(currSize) / Double(totalSize)
        // dbgPrint("downloadAmount = \(downloadAmount), currSize = \(currSize), totalSize = \(totalSize)")
        
      }) { (data: Data?, error: Error?, fromCache: Bool) in
      self.downloadState = CZHttpFileManager.shared.downloadState(forURL: feed.url).rawValue
      dbgPrint("Downloaded url - \(feed.url), downloadState = \(downloadState)")

    }
  }
  
  var body: some View {
    VStack {
      ProgressView(feed.url.absoluteString, value: downloadAmount, total: 1)
      
      Text(downloadState)
      
      Button("Download") {
        downloadFile()
      }
    }
    .onAppear {
      downloadFile()
    }
  }
}
