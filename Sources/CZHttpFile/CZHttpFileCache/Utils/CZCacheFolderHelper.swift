import Foundation
import CZUtils

/// Helper class of the cached folder.
internal class CZCacheFolderHelper: NSObject {
  
  private(set) lazy var cacheFolder: String = {
    let cacheFolder = CZFileHelper.documentDirectory + cacheFolderName + "/"
    dbgPrintWithFunc(self, "cacheFolder = \(cacheFolder)")
    CZFileHelper.createDirectoryIfNeeded(at: cacheFolder)
    return cacheFolder
  }()
  private var cacheFolderName: String
  
  init(cacheFolderName: String) {
    self.cacheFolderName = cacheFolderName
    super.init()
  }
}
