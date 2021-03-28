import UIKit
import CZUtils

public typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
public typealias CleanDiskCacheCompletion = () -> Void
internal typealias CachedItemsDict = [String: [String: Any]]

/**
 Manager maintains the disk cache, including files read/write, cachedItemsDict.
 */
internal class CZDiskCacheManager<DataType: NSObjectProtocol>: NSObject {
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
      
  private(set) var maxCacheAge: TimeInterval
  private(set) var maxCacheSize: Int
  private var ioQueue: DispatchQueue {
    return httpFileCache.ioQueue
  }
  private var fileManager: FileManager

  public init(maxCacheAge: TimeInterval,
              maxCacheSize: Int,
              cacheFolderName: String,
              httpFileCache: CZBaseHttpFileCache<DataType>) {
    self.maxCacheAge = maxCacheAge
    self.maxCacheSize = maxCacheSize
    self.cacheFolderName = cacheFolderName
    self.fileManager = FileManager()
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
  
  func setCachedItemsDictForNewURL(_ httpURL: URL, fileSize: Int) {
    let (_, cacheKey) = getCacheFileInfo(forURL: httpURL)
    setCachedItemsDict(key: cacheKey, subkey: CacheConstant.kFileModifiedDate, value: NSDate())
    setCachedItemsDict(key: cacheKey, subkey: CacheConstant.kFileVisitedDate, value: NSDate())
    setCachedItemsDict(key: cacheKey, subkey: CacheConstant.kFileSize, value: fileSize)
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
    let cacheFileInfo = getCacheFileInfo(forURL: url)
    removeCachedItemsDict(forKey: cacheFileInfo.cacheKey)
  }
  
  func flushCachedItemsDictToDisk(_ cachedItemsDict: CachedItemsDict) {
    (cachedItemsDict as NSDictionary).write(to: cachedItemsDictFileURL, atomically: true)
  }
}

// MARK: - Helper methods

extension CZDiskCacheManager {
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

// MARK: - Clean DiskCache

internal extension CZDiskCacheManager {
  func cleanDiskCacheIfNeeded(completion: CleanDiskCacheCompletion? = nil){
    let currDate = Date()
    
    // 1. Clean disk by age
    let removeFileURLs = cachedItemsDictLock.writeLock { (cachedItemsDict: inout CachedItemsDict) -> [URL] in
      var removedKeys = [String]()
      
      // Remove key if its fileModifiedDate exceeds maxCacheAge
      cachedItemsDict.forEach { (keyValue: (key: String, value: [String : Any])) in
        if let modifiedDate = keyValue.value[CacheConstant.kFileModifiedDate] as? Date,
           currDate.timeIntervalSince(modifiedDate) > self.maxCacheAge {
          removedKeys.append(keyValue.key)
          cachedItemsDict.removeValue(forKey: keyValue.key)
        }
      }
      self.flushCachedItemsDictToDisk(cachedItemsDict)
      let removeFileURLs = removedKeys.compactMap{ self.cacheFileURL(forKey: $0) }
      return removeFileURLs
    }
    // Remove corresponding files from disk
    self.ioQueue.async(flags: .barrier) { [weak self] in
      guard let `self` = self else { return }
      removeFileURLs?.forEach {
        do {
          try self.fileManager.removeItem(at: $0)
        } catch {
          assertionFailure("Failed to remove file. Error - \(error.localizedDescription)")
        }
      }
    }
    
    // 2. Clean disk by maxSize setting: based on visited date - simple LRU
    if self.totalCachedFileSize > self.maxCacheSize {
      let expectedCacheSize = self.maxCacheSize / 2
      let expectedReduceSize = self.totalCachedFileSize - expectedCacheSize
      
      let removeFileURLs = cachedItemsDictLock.writeLock { (cachedItemsDict: inout CachedItemsDict) -> [URL] in
        // Sort files with last visted date
        let sortedItemsInfo = cachedItemsDict.sorted { (keyValue1: (key: String, value: [String : Any]),
                                                        keyValue2: (key: String, value: [String : Any])) -> Bool in
          if let modifiedDate1 = keyValue1.value[CacheConstant.kFileVisitedDate] as? Date,
             let modifiedDate2 = keyValue2.value[CacheConstant.kFileVisitedDate] as? Date {
            return modifiedDate1.timeIntervalSince(modifiedDate2) < 0
          } else {
            fatalError()
          }
        }
        
        var removedFilesSize: Int = 0
        var removedKeys = [String]()
        for (key, value) in sortedItemsInfo {
          if removedFilesSize >= expectedReduceSize {
            break
          }
          cachedItemsDict.removeValue(forKey: key)
          removedKeys.append(key)
          let oneFileSize = (value[CacheConstant.kFileSize] as? Int) ?? 0
          removedFilesSize += oneFileSize
        }
        self.flushCachedItemsDictToDisk(cachedItemsDict)
        return removedKeys.compactMap { self.cacheFileURL(forKey: $0) }
      }
      
      // Remove corresponding files from disk
      self.ioQueue.async(flags: .barrier) { [weak self] in
        guard let `self` = self else { return }
        removeFileURLs?.forEach {
          do {
            try self.fileManager.removeItem(at: $0)
          } catch {
            assertionFailure("Failed to remove file. Error - \(error.localizedDescription)")
          }
        }
      }
    }
    
    completion?()
  }
}
// MARK: - Private methods

private extension CZDiskCacheManager {
  func loadCachedItemsDict() -> CachedItemsDict? {
    return NSDictionary(contentsOf: cachedItemsDictFileURL) as? CachedItemsDict
  }
}
