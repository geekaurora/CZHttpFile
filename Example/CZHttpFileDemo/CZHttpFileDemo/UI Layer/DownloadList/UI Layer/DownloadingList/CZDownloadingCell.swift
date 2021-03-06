import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct CZDownloadingCell: View {
  @State private var downloadAmount = 0.0
  @State private var downloadState = ""
  
  let download: CZDownload
  
  func downloadFile() {
    CZHttpFileManager.shared.downloadFile(
      url: download.url,
      progress: { (currSize: Int64, totalSize: Int64, downloadURL: URL) in
        self.downloadState = CZHttpFileManager.shared.downloadState(forURL: download.url).rawValue
        self.downloadAmount = Double(currSize) / Double(totalSize)
        // dbgPrint("downloadAmount = \(downloadAmount), currSize = \(currSize), totalSize = \(totalSize)")
        
      }) { (data: Data?, error: Error?, fromCache: Bool) in
      self.downloadState = CZHttpFileManager.shared.downloadState(forURL: download.url).rawValue
      dbgPrint("Downloaded url - \(download.url), downloadState = \(downloadState)")

    }
  }
  
  var body: some View {
    VStack {
      ProgressView(download.url.absoluteString, value: downloadAmount, total: 1)
      Text(downloadState)
      
//      Button("CZDownload")
//      {
//        downloadFile()
//      }
    }
    .onAppear {
      // downloadFile()
    }
  }
}
