import SwiftUI
import CZHttpFile
import CZAVPlayer

struct ContentView: View {
  var body: some View {
    // let url = URL(string: "https://d37t5b145o82az.cloudfront.net/pictures/01bff78eae0870a01ed491ef86405bdf.jpg")!
    let url = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!

    // https://stackoverflow.com/questions/16097404/what-is-difference-between-urlwithstring-and-fileurlwithpath-of-nsurl
//    let cacheFileUrl = URL(fileURLWithPath: "file:///Users/administrator/Library/Developer/CoreSimulator/Devices/8FF21713-4F10-4410-9700-AFE7376AECCE/data/Containers/Data/Application/AA6183C3-278B-47B2-9AD9-9AD28DCDA2EE/Documents/CZHttpFileCache/a25fb258deab6f447a400683739521e6")
    let cacheFileUrl = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")
    
    let audioInfo = CZAudioInfo(url: cacheFileUrl, title: "Test")
    AVPlayerView(audioInfo: audioInfo)
    
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
