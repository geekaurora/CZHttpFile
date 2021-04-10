import SwiftUI
import CZUtils
import CZHttpFile

struct CZDownloadingCell: View {
  @State private var downloadState = ""
  
  let download: CZDownload
  
  var body: some View {
    VStack {
      ProgressView(download.url.absoluteString, value: download.progress, total: 1)
      Text(downloadState)
    }
  }
}
