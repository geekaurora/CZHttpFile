import UIKit
import CZUtils

internal typealias CachedItemsInfo = [String: [String: Any]]

internal class CZCachedItemsInfoManager<DataType: NSObjectProtocol>: NSObject {
    
  private var cacheFileManager: CZCacheFileManager
  // TODO: move helper methods to CZCacheUtils to untangle deps on CZBaseHttpFileCache.
  private weak var httpFileCache: CZBaseHttpFileCache<DataType>!
  
  private lazy var cachedItemsInfoFileURL: URL = {
    return URL(fileURLWithPath: cacheFileManager.cacheFolder + CacheConstant.kCachedItemsInfoFile)
  }()
  internal lazy var cachedItemsInfoLock: CZMutexLock<CachedItemsInfo> = {
    let cachedItemsInfo: CachedItemsInfo = loadCachedItemsInfo() ?? [:]
    return CZMutexLock(cachedItemsInfo)
  }()
      
  public init(cacheFileManager: CZCacheFileManager,
              httpFileCache: CZBaseHttpFileCache<DataType>) {
    self.cacheFileManager = cacheFileManager
    self.httpFileCache = httpFileCache
    super.init()
  }
  
  var totalCachedFileSize: Int {
    return cachedItemsInfoLock.readLock { [weak self] (cachedItemsInfo: CachedItemsInfo) -> Int in
      guard let `self` = self else {return 0}
      return self.getSizeWithoutLock(cachedItemsInfo: cachedItemsInfo)
    } ?? 0
  }

  /// Get total cache size with `cachedItemsInfo`.
  func getSizeWithoutLock(cachedItemsInfo: CachedItemsInfo) -> Int {
    var totalCacheSize: Int = 0
    for (_, value) in cachedItemsInfo {
      let oneFileSize = (value[CacheConstant.kFileSize] as? Int)  ?? 0
      totalCacheSize += oneFileSize
    }
    return totalCacheSize
  }
  
  /// Get total cache size with `cachedItemsInfo`.
  func urlExistsInCache(_ httpURL: URL) -> Bool {
    return cachedItemsInfoLock.readLock { [weak self] (cachedItemsInfo) -> Bool? in
      guard let `self` = self else { return false}
      
      let (_, cacheKey) = self.httpFileCache.getCacheFileInfo(forURL: httpURL)
      let urlExistsInCache = (cachedItemsInfo[cacheKey] != nil)
      return urlExistsInCache
    } ?? false
  }
  
  func loadCachedItemsInfo() -> CachedItemsInfo? {
    return NSDictionary(contentsOf: cachedItemsInfoFileURL) as? CachedItemsInfo
  }
  
  func setCachedItemsInfo(key: String, subkey: String, value: Any) {
    cachedItemsInfoLock.writeLock { [weak self] (cachedItemsInfo) -> Void in
      guard let `self` = self else { return }
      if cachedItemsInfo[key] == nil {
        cachedItemsInfo[key] = [:]
      }
      cachedItemsInfo[key]?[subkey] = value
      self.flushCachedItemsInfoToDisk(cachedItemsInfo)
    }
  }
  
  func removeCachedItemsInfo(forKey key: String) {
    cachedItemsInfoLock.writeLock { [weak self] (cachedItemsInfo) -> Void in
      guard let `self` = self else { return }
      cachedItemsInfo.removeValue(forKey: key)
      self.flushCachedItemsInfoToDisk(cachedItemsInfo)
    }
  }
  
  func removeCachedItemsInfo(forUrl url: URL) {
    let cacheFileInfo = httpFileCache.getCacheFileInfo(forURL: url)
    removeCachedItemsInfo(forKey: cacheFileInfo.cacheKey)
  }
  
  func flushCachedItemsInfoToDisk(_ cachedItemsInfo: CachedItemsInfo) {
    (cachedItemsInfo as NSDictionary).write(to: cachedItemsInfoFileURL, atomically: true)
  }
}
