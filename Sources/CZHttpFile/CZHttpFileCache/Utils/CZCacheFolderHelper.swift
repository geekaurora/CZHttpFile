import Foundation
import CZUtils

/// CacheFileManager helper class.
internal class CZCacheFolderHelper: NSObject {
  
  private(set) lazy var cacheFolder: String = {
    let cacheFolder = CZFileHelper.documentDirectory + cacheFolderName + "/"
    
    let fileManager = FileManager()
    if !fileManager.fileExists(atPath: cacheFolder) {
      do {
        try fileManager.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
      } catch {
        assertionFailure("Failed to create CacheFolder! Error - \(error.localizedDescription); Folder - \(cacheFolder)")
      }
    }
    dbgPrint("\(type(of: self)) - \(#function): cacheFolder = \(cacheFolder)")
    return cacheFolder
  }()
  private var cacheFolderName: String
  
  init(cacheFolderName: String) {
    self.cacheFolderName = cacheFolderName
    super.init()
  }
}
