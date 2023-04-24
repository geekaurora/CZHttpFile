import SwiftUI
import CZUtils
import CZHttpFile
import CZHttpFileListSwiftUI

struct TabsView: View {
  
  var body: some View {
    TabView {
      SingleDownloadView()
        .tabItem {
          Image(systemName: "house")
          Text("Home")
        }
      
      MultiDownloadsView()
        .tabItem {
          Image(systemName: "square.and.arrow.down")
          Text("Download")
        }
      
      DownloadListTab(cache: CZHttpFileManager.shared.cache)
        .tabItem {
          Image(systemName: "square.and.arrow.down")
          Text("Downloading")
        }
      
    }.onAppear() {      
    }
  }
}
