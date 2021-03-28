import UIKit
import CZUtils

internal typealias CachedItemsDict = [String: [String: Any]]

/**
 
 */
internal class CZCachedItemsDictManager<DataType: NSObjectProtocol>: NSObject {
  private var cacheFileManager: CZCacheFileManager
  // TODO: move helper methods to CZCacheUtils to untangle deps on CZBaseHttpFileCache.
  private weak var httpFileCache: CZBaseHttpFileCache<DataType>!
  
  private lazy var cachedItemsDictFileURL: URL = {
    return URL(fileURLWithPath: cacheFileManager.cacheFolder + CacheConstant.kCachedItemsDictFile)
  }()
  
  internal lazy var cachedItemsDictLock: CZMutexLock<CachedItemsDict> = {
    let cachedItemsDict: CachedItemsDict = loadCachedItemsDict() ?? [:]
    return CZMutexLock(cachedItemsDict)
  }()
      
  public init(cacheFileManager: CZCacheFileManager,
              httpFileCache: CZBaseHttpFileCache<DataType>) {
    self.cacheFileManager = cacheFileManager
    self.httpFileCache = httpFileCache
    super.init()
  }
  
  var totalCachedFileSize: Int {
    return cachedItemsDictLock.readLock { [weak self] (cachedItemsDict: CachedItemsDict) -> Int in
      guard let `self` = self else {return 0}
      return self.getSizeWithoutLock(cachedItemsDict: cachedItemsDict)
    } ?? 0
  }

  /// Get total cache size with `cachedItemsDict`.
  func getSizeWithoutLock(cachedItemsDict: CachedItemsDict) -> Int {
    var totalCacheSize: Int = 0
    for (_, value) in cachedItemsDict {
      let oneFileSize = (value[CacheConstant.kFileSize] as? Int)  ?? 0
      totalCacheSize += oneFileSize
    }
    return totalCacheSize
  }
  
  /// Get total cache size with `cachedItemsDict`.
  func urlExistsInCache(_ httpURL: URL) -> Bool {
    return cachedItemsDictLock.readLock { [weak self] (cachedItemsDict) -> Bool? in
      guard let `self` = self else { return false}
      
      let (_, cacheKey) = self.httpFileCache.getCacheFileInfo(forURL: httpURL)
      let urlExistsInCache = (cachedItemsDict[cacheKey] != nil)
      return urlExistsInCache
    } ?? false
  }
  
  func setCachedItemsDict(key: String, subkey: String, value: Any) {
    cachedItemsDictLock.writeLock { [weak self] (cachedItemsDict) -> Void in
      guard let `self` = self else { return }
      if cachedItemsDict[key] == nil {
        cachedItemsDict[key] = [:]
      }
      cachedItemsDict[key]?[subkey] = value
      self.flushCachedItemsDictToDisk(cachedItemsDict)
    }
  }
  
  func removeCachedItemsDict(forKey key: String) {
    cachedItemsDictLock.writeLock { [weak self] (cachedItemsDict) -> Void in
      guard let `self` = self else { return }
      cachedItemsDict.removeValue(forKey: key)
      self.flushCachedItemsDictToDisk(cachedItemsDict)
    }
  }
  
  func removeCachedItemsDict(forUrl url: URL) {
    let cacheFileInfo = httpFileCache.getCacheFileInfo(forURL: url)
    removeCachedItemsDict(forKey: cacheFileInfo.cacheKey)
  }
  
  func flushCachedItemsDictToDisk(_ cachedItemsDict: CachedItemsDict) {
    (cachedItemsDict as NSDictionary).write(to: cachedItemsDictFileURL, atomically: true)
  }
}

// MARK: - Private methods

private extension CZCachedItemsDictManager {
  func loadCachedItemsDict() -> CachedItemsDict? {
    return NSDictionary(contentsOf: cachedItemsDictFileURL) as? CachedItemsDict
  }
}
