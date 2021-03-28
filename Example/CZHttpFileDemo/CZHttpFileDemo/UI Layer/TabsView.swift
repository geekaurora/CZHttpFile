import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct TabsView: View {
  
  var body: some View {
    // SingleDownloadView()
    
//    MultiDownloadsView()
//      .onAppear() {
//        CZHttpFileDownloaderConstant.shouldObserveOperations = true
//        // CZHttpFileManager.Config.maxConcurrencies = 7
//      }
    
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
      
      CZDownloadingList()
        .tabItem {
          Image(systemName: "square.and.arrow.down")
          Text("Downloading")
        }
      
    }
    
  }
}
