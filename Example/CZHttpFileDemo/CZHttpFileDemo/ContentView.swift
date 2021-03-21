import SwiftUI
import CZHttpFile
import CZAVPlayer

struct ContentView: View {
  var body: some View {
    // let url = URL(string: "https://d37t5b145o82az.cloudfront.net/pictures/01bff78eae0870a01ed491ef86405bdf.jpg")!

    // https://stackoverflow.com/questions/16097404/what-is-difference-between-urlwithstring-and-fileurlwithpath-of-nsurl
//    let cacheFileUrl = URL(fileURLWithPath: "file:///Users/administrator/Library/Developer/CoreSimulator/Devices/8FF21713-4F10-4410-9700-AFE7376AECCE/data/Containers/Data/Application/13DC4A55-0659-4A7C-9441-CFBFFF0DA262/Documents/CZHttpFileCache/a25fb258deab6f447a400683739521e6.m4a")
    
    let url = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!
    // let cacheFileInfo = CZHttpFileManager.shared.cache.getCacheFileInfo(forURL: url)
    
    //let cacheFileUrl = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")
    
    let cacheFileUrl = Bundle.main.url(forResource: "a25fb258deab6f447a400683739521e6", withExtension: "m4a")
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
