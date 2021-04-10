import SwiftUI
import CZUtils
import CZHttpFile

public struct DownloadListTab: View {
  @State private var selectedIndex = 0
  
  public init() {}
  
  public var body: some View {
    VStack {
      Picker(selection: $selectedIndex, label: Text("")) {
        Text("Downloaded").tag(0)
        Text("Downloading").tag(1)
      }
      .pickerStyle(SegmentedPickerStyle())
      
      if selectedIndex == 0 {
        CZDownloadedList()        
      } else {
        CZDownloadingList()
      }
    }.onAppear() {
      CZHttpFileDownloaderConfig.shouldObserveDownloadingProgress = true
    }
  }
}
