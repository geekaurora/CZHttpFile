import UIKit
import CZUtils

internal typealias CachedItemsInfo = [String: [String: Any]]

internal class CZCachedItemsInfoManager: NSObject {
  public typealias CleanDiskCacheCompletion = () -> Void
  
  private var ioQueue: DispatchQueue

  private var fileManager: FileManager
  private var cacheFileManager: CZCacheFileManager
  private var operationQueue: OperationQueue
  private var hasCachedItemsInfoToFlushToDisk: Bool = false
  
  private lazy var cachedItemsInfoFileURL: URL = {
    return URL(fileURLWithPath: cacheFileManager.cacheFolder + CacheConstant.kCachedItemsInfoFile)
  }()
  private lazy var cachedItemsInfoLock: CZMutexLock<CachedItemsInfo> = {
    let cachedItemsInfo: CachedItemsInfo = loadCachedItemsInfo() ?? [:]
    return CZMutexLock(cachedItemsInfo)
  }()
    
  private(set) var maxCacheAge: TimeInterval
  private(set) var maxCacheSize: Int
  
  public init(cacheFileManager: CZCacheFileManager,
                maxCacheAge: TimeInterval = CacheConstant.kMaxFileAge,
              maxCacheSize: Int = CacheConstant.kMaxCacheSize) {
    operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 60
    
    ioQueue = DispatchQueue(label: CacheConstant.ioQueueLabel,
                            qos: .userInitiated,
                            attributes: .concurrent)
    fileManager = FileManager()
    
    self.cacheFileManager = cacheFileManager
    self.maxCacheAge = maxCacheAge
    self.maxCacheSize = maxCacheSize
    super.init()
  }
  
  var size: Int {
    return cachedItemsInfoLock.readLock { [weak self] (cachedItemsInfo: CachedItemsInfo) -> Int in
      guard let `self` = self else {return 0}
      return self.getSizeWithoutLock(cachedItemsInfo: cachedItemsInfo)
    } ?? 0
  }
}

// MARK: - Helper methods

extension CZCachedItemsInfoManager {
  typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
  
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
  
  func getCacheFileInfo(forURL url: URL) -> CacheFileInfo {
    let urlString = url.absoluteString
    let cacheKey = urlString.MD5 + urlString.fileType(includingDot: true)
    let fileURL = URL(fileURLWithPath: cacheFileManager.cacheFolder + cacheKey)
    return (fileURL: fileURL, cacheKey: cacheKey)
  }
}

// MARK: - CachedItemsInfo

internal extension CZCachedItemsInfoManager {
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
      
      let (_, cacheKey) = self.getCacheFileInfo(forURL: httpURL)
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
    let cacheFileInfo = self.getCacheFileInfo(forURL: url)
    removeCachedItemsInfo(forKey: cacheFileInfo.cacheKey)
  }
  
  func flushCachedItemsInfoToDisk(_ cachedItemsInfo: CachedItemsInfo) {
    (cachedItemsInfo as NSDictionary).write(to: cachedItemsInfoFileURL, atomically: true)
  }
}
