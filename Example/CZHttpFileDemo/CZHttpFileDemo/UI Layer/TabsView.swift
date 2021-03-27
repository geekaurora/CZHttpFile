import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct TabsView: View {
  
  var body: some View {
    // SingleDownloadView()
    
    MultiDownloadsView()
      .onAppear() {
        // CZHttpFileManager.Config.maxConcurrencies = 7
      }
  }
}
