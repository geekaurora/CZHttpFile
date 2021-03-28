import UIKit
import CZUtils

public typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
internal typealias CachedItemsDict = [String: [String: Any]]

internal class CZCachedItemsDictManager<DataType: NSObjectProtocol>: NSObject {
  private(set) lazy var cacheFolderHelper: CZCacheFolderHelper = {
    return CZCacheFolderHelper(cacheFolderName: cacheFolderName)
  }()
  
  // TODO: move helper methods to CZCacheUtils to untangle deps on CZBaseHttpFileCache.
  private weak var httpFileCache: CZBaseHttpFileCache<DataType>!
  private var cacheFolderName: String
  
  private lazy var cachedItemsDictFileURL: URL = {
    return URL(fileURLWithPath: cacheFolderHelper.cacheFolder + CacheConstant.kCachedItemsDictFile)
  }()
  
  internal lazy var cachedItemsDictLock: CZMutexLock<CachedItemsDict> = {
    let cachedItemsDict: CachedItemsDict = loadCachedItemsDict() ?? [:]
    return CZMutexLock(cachedItemsDict)
  }()
      
  public init(cacheFolderName: String,
              httpFileCache: CZBaseHttpFileCache<DataType>) {
    self.cacheFolderName = cacheFolderName
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
      
      let (_, cacheKey) = self.getCacheFileInfo(forURL: httpURL)
      let urlExistsInCache = (cachedItemsDict[cacheKey] != nil)
      return urlExistsInCache
    } ?? false
  }
  
  // MARK: - cachedItemsDict
  
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
    let cacheFileInfo = getCacheFileInfo(forURL: url)
    removeCachedItemsDict(forKey: cacheFileInfo.cacheKey)
  }
  
  func flushCachedItemsDictToDisk(_ cachedItemsDict: CachedItemsDict) {
    (cachedItemsDict as NSDictionary).write(to: cachedItemsDictFileURL, atomically: true)
  }
}

// MARK: - Helper methods

extension CZCachedItemsDictManager {
  /**
   Returns cached file URL if has been downloaded, otherwise nil.
   */
  func cachedFileURL(forURL httpURL: URL?) -> (fileURL: URL?, isExisting: Bool) {
    guard let httpURL = httpURL else {
      return (nil, false)
    }
    let cacheFileInfo = getCacheFileInfo(forURL: httpURL)
    let fileURL = cacheFileInfo.fileURL
    let isExisting = urlExistsInCache(httpURL)
    return (fileURL, isExisting)
  }
  
  func cacheFileURL(forKey key: String) -> URL {
    return URL(fileURLWithPath: cacheFolderHelper.cacheFolder + key)
  }
    
  func getCacheFileInfo(forURL url: URL) -> CacheFileInfo {
    let urlString = url.absoluteString
    let cacheKey = urlString.MD5 + urlString.fileType(includingDot: true)
    let fileURL = URL(fileURLWithPath: cacheFolderHelper.cacheFolder + cacheKey)
    return (fileURL: fileURL, cacheKey: cacheKey)
  }
}

// MARK: - Private methods

private extension CZCachedItemsDictManager {
  func loadCachedItemsDict() -> CachedItemsDict? {
    return NSDictionary(contentsOf: cachedItemsDictFileURL) as? CachedItemsDict
  }
}
