import SwiftUI
import CZHttpFile
import CZAVPlayer

/**
 Bundle
 file:///Users/administrator/Library/Developer/CoreSimulator/Devices/8FF21713-4F10-4410-9700-AFE7376AECCE/data/Containers/Bundle/Application/BD017B4B-CAB3-4486-9ECC-1C233241C5D1/CZHttpFileDemo.app/a25fb258deab6f447a400683739521e6.m4a
 
 Cache:
 */
struct ContentView: View {
  let url = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!

  var cacheFileUrl: URL? {
    if true {
      let cacheFileInfo = CZHttpFileManager.shared.cache.getCacheFileInfo(forURL: url)
      return cacheFileInfo.fileURL
    } else {
       return Bundle.main.url(forResource: "a25fb258deab6f447a400683739521e6", withExtension: "m4a")
    }
  }

  var body: some View {
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
