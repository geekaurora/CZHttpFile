import SwiftUI
import CZHttpFile

struct ContentView: View {
  var body: some View {
    let url = URL(string: "")!

    Button("Download") {
      CZHttpFileManager.shared.downloadFile(
      url: url) { (data: Data?, error: Error?, fromCache: Bool) in
        
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
