import SwiftUI
import CZUtils
import CZHttpFile
import CZAVPlayer

/*
 struct TabsView: View {
     @State private var favoriteColor = 0

     var body: some View {
         VStack {
             Picker(selection: $favoriteColor, label: Text("What is your favorite color?")) {
                 Text("Red").tag(0)
                 Text("Green").tag(1)
                 Text("Blue").tag(2)
             }
             .pickerStyle(SegmentedPickerStyle())

             Text("Value: \(favoriteColor)")
         }
     }
 }

 */
struct TabsView: View {
  @State private var favoriteColor = 0

  var body: some View {
    VStack {
        Picker(selection: $favoriteColor, label: Text("What is your favorite color?")) {
            Text("Downloading").tag(0)
            Text("Downloaded").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())

      if favoriteColor == 0 {
        CZDownloadedList()
        
      } else {
        CZDownloadingList()
      }
    }
    
//    TabView {
//      SingleDownloadView()
//        .tabItem {
//          Image(systemName: "house")
//          Text("Home")
//        }
//
//      MultiDownloadsView()
//        .tabItem {
//          Image(systemName: "square.and.arrow.down")
//          Text("Download")
//        }
//
//      CZDownloadingList()
//        .tabItem {
//          Image(systemName: "square.and.arrow.down")
//          Text("Downloading")
//        }
//
//      CZDownloadedList()
//        .tabItem {
//          Image(systemName: "square.and.arrow.down")
//          Text("Downloaded")
//        }
//
//    }
    
  }
}
