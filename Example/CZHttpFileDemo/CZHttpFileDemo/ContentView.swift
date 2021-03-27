import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

struct ContentView: View {
  let url = URL(string: "https://github.com/geekaurora/terrace/raw/master/media/starter01.m4a")!
  
  var cacheFileUrl: URL? {
      let cacheFileInfo = CZHttpFileManager.shared.cache.getCacheFileInfo(forURL: url)
      return cacheFileInfo.fileURL
  }

  var body: some View {
//    let audioInfo = CZAudioInfo(url: cacheFileUrl, title: "TestAudio")
//    AVPlayerView(audioInfo: audioInfo)
    
    
    Button("Download") {
      CZHttpFileManager.shared.downloadFile(
        url: url,
        progress: { (currSize: Int64, totalSize: Int64, downloadURL: URL) in
          dbgPrint("Downloaded url - currSize = \(currSize), totalSize = \(totalSize)")
          
        }) { (data: Data?, error: Error?, fromCache: Bool) in
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
