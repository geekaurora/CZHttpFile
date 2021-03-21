import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

/**
 Bundle
 file:///Users/administrator/Library/Developer/CoreSimulator/Devices/8FF21713-4F10-4410-9700-AFE7376AECCE/data/Containers/Bundle/Application/BD017B4B-CAB3-4486-9ECC-1C233241C5D1/CZHttpFileDemo.app/a25fb258deab6f447a400683739521e6.m4a
 
 Cache:
 file:///Users/administrator/Library/Developer/CoreSimulator/Devices/8FF21713-4F10-4410-9700-AFE7376AECCE/data/Containers/Data/Application/97180F65-D623-47E3-B55F-0694511282B1/Documents/CZHttpFileCache/a25fb258deab6f447a400683739521e6.m4a
 
 *Cache from CZHttpFileManager:
 file:///Users/administrator/Library/Developer/CoreSimulator/Devices/8FF21713-4F10-4410-9700-AFE7376AECCE/data/Containers/Data/Application/098E3EE4-5CC3-44CF-AEDF-BFE48BDEB65C/Documents/CZHttpFileCache/a25fb258deab6f447a400683739521e6
 */
struct ContentView: View {
  let url = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!

  var cacheFileUrl: URL? {
    if true {
      let cacheFileInfo = CZHttpFileManager.shared.cache.getCacheFileInfo(forURL: url)
      return cacheFileInfo.fileURL
    } else {
       return Bundle.main.url(forResource: "a25fb258deab6f447a400683739521e6", withExtension: nil)
    }
  }

  var body: some View {
    let audioInfo = CZAudioInfo(url: cacheFileUrl, title: "TestAudio")
    AVPlayerView(audioInfo: audioInfo)
    
    Button("Download") {
      CZHttpFileManager.shared.downloadFile(
        url: url) { (data: Data?, error: Error?, fromCache: Bool) in
          dbgPrint("Downloaded url - \(url)")
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
