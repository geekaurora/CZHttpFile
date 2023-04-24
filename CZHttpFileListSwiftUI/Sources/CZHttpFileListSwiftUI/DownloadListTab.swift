import SwiftUI
import CZUtils
import CZHttpFile

/**
 Tab of the cache information: currentCacheSize, downloaded URLs.
 
 ### Usage
 1. import CZHttpFileListSwiftUI
 
 2. Add the following code to your `TabView`:
 ```
 DownloadListTab()
   .tabItem {
     Image(systemName: "square.and.arrow.down")
     Text("Download")
   }
 ```
 */
public struct DownloadListTab: View {
  @State private var selectedIndex = 0
  
  private let cache: CZBaseHttpFileCacheProtocol
  
  public init(cache: CZBaseHttpFileCacheProtocol) {
    self.cache = cache
  }
  
  public var body: some View {
    VStack {
      CZDownloadedList(cache: cache)
      
//      Picker(selection: $selectedIndex, label: Text("")) {
//        Text("Downloaded").tag(0)
//        Text("Downloading").tag(1)
//      }
//      .pickerStyle(SegmentedPickerStyle())
//
//      if selectedIndex == 0 {
//        CZDownloadedList()
//      } else {
//        CZDownloadingList()
//      }
    }.onAppear() {
      CZHttpFileDownloaderConfig.shouldObserveDownloadingProgress = true
    }
  }
}
