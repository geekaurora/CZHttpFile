import UIKit
import CZUtils

public typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
public typealias CleanDiskCacheCompletion = () -> Void
public typealias SetCacheFileCompletion = () -> Void
internal typealias CachedItemsDict = [String: [String: Any]]

/**
 Manager that maintains the disk cache including file read/write and cachedItemsDict.
 */
internal class CZDiskCacheManager<DataType: NSObjectProtocol>: NSObject {
  private(set) lazy var cacheFolderHelper: CZCacheFolderHelper = {
    return CZCacheFolderHelper(cacheFolderName: cacheFolderName)
  }()
  
  internal typealias TransformMetadataToCachedData = (_ data: Data) -> DataType?
  
  private var cacheFolderName: String
  
  private lazy var cachedItemsDictFileURL: URL = {
    return URL(fileURLWithPath: cacheFolderHelper.cacheFolder + CacheConstant.kCachedItemsDictFile)
  }()
  
  lazy var cachedItemsDictLock: CZMutexLock<CachedItemsDict> = {
    let cachedItemsDict: CachedItemsDict = loadCachedItemsDict() ?? [:]
    return CZMutexLock(cachedItemsDict)
  }()
      
  let maxCacheAge: TimeInterval
  let maxCacheSize: Int
  let ioQueue: DispatchQueue
  private(set) weak var downloadedObserverManager: CZDownloadedObserverManager?

  private let fileManager: FileManager
  private let transformMetadataToCachedData: TransformMetadataToCachedData
  
  public init(maxCacheAge: TimeInterval,
              maxCacheSize: Int,
              cacheFolderName: String,
              transformMetadataToCachedData: @escaping TransformMetadataToCachedData,
              downloadedObserverManager: CZDownloadedObserverManager? = nil) {
    self.maxCacheAge = maxCacheAge
    self.maxCacheSize = maxCacheSize
    self.cacheFolderName = cacheFolderName
    self.downloadedObserverManager = downloadedObserverManager
    self.transformMetadataToCachedData = transformMetadataToCachedData
    self.fileManager = FileManager()

    self.ioQueue = DispatchQueue(
      label: CacheConstant.ioQueueLabel,
      qos: .userInitiated,
      attributes: .concurrent)
    
    super.init()
  }
  
  var totalCachedFileSize: Int {
    return cachedItemsDictLock.readLock { [weak self] (cachedItemsDict: CachedItemsDict) -> Int in
      guard let `self` = self else {return 0}
      return self.getSizeWithoutLock(cachedItemsDict: cachedItemsDict)
    } ?? 0
  }

  /**
   Get total cache size with `cachedItemsDict`.
   */
  func getSizeWithoutLock(cachedItemsDict: CachedItemsDict) -> Int {
    var totalCacheSize: Int = 0
    for (_, value) in cachedItemsDict {
      let oneFileSize = (value[CacheConstant.kFileSize] as? Int)  ?? 0
      totalCacheSize += oneFileSize
    }
    return totalCacheSize
  }
    
  /**
   Returns whether `httpURL` file has been downloaded  and exists in the cache.
   */
  func urlExistsInCache(_ httpURL: URL) -> Bool {
    return cachedItemsDictLock.readLock { [weak self] (cachedItemsDict) -> Bool? in
      guard let `self` = self else { return false}
      
      let (_, cacheKey) = self.getCacheFileInfo(forURL: httpURL)
      let urlExistsInCache = (cachedItemsDict[cacheKey] != nil)
      return urlExistsInCache
    } ?? false
  }
}

// MARK: - Set / Get Cache file
  
extension CZDiskCacheManager {
  /**
   Set the cache file for `url`.
   - Note: there're two completions for different usages.
   Should wait for `completeSetCachedItemsDict` before completes downloading to ensure downloaded state correct,
   which repies on `cachedItemsDict`.
   
   - Parameters:
     - completeSetCachedItemsDict: called when completes setting CachedItemsDict.
     - completeSaveCachedFile: called when completes saving file.
   */
  public func setCacheFile(withUrl url: URL,
                           data: Data?,
                           completeSetCachedItemsDict: SetCacheFileCompletion? = nil,
                           completeSaveCachedFile: SetCacheFileCompletion? = nil) {
    guard let data = data.assertIfNil else { return }
    let (fileURL, cacheKey) = getCacheFileInfo(forURL: url)
    
    // Disk cache
    ioQueue.async(flags: .barrier) { [weak self] in
      guard let `self` = self else { return }
      do {
        self.setCachedItemsDictForNewURL(url, fileSize: data.count)
        completeSetCachedItemsDict?()
        try data.write(to: fileURL)
        completeSaveCachedFile?()
      } catch {
        assertionFailure("Failed to write file. Error - \(error.localizedDescription)")
      }
    }
  }
  
  public func getCachedFile(withUrl url: URL,
                            completion: @escaping (DataType?) -> Void)  {
    let (fileURL, cacheKey) = getCacheFileInfo(forURL: url)
    
    // Read data from disk cache
    self.ioQueue.sync {
      if let data = try? Data(contentsOf: fileURL),
         let image = transformMetadataToCachedData(data).assertIfNil {
        // Update last visited date
        self.setCachedItemsDict(key: cacheKey, subkey: CacheConstant.kFileVisitedDate, value: NSDate())
        completion(image)
      } else {
        completion(nil)
      }
    }
  }
}

// MARK: - cachedItemsDict
  
extension CZDiskCacheManager {
  /**
   Set information for newly downloaded `httpURL` - includes urlString, modifiedDate, visitedDate, fileSize.
   */
  func setCachedItemsDictForNewURL(_ httpURL: URL, fileSize: Int) {
    let (_, cacheKey) = getCacheFileInfo(forURL: httpURL)
    
    cachedItemsDictLockWrite { [weak self] (cachedItemsDict) -> Void in
      guard let `self` = self else { return }
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kHttpUrlString, value: httpURL.absoluteString)
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kFileModifiedDate, value: NSDate())
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kFileVisitedDate, value: NSDate())
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kFileSize, value: fileSize)
    }
  }
   
  func setCachedItemsDict(key: String, subkey: String, value: Any) {
    cachedItemsDictLockWrite { [weak self] (cachedItemsDict) -> Void in
      guard let `self` = self else { return }
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: key, subkey: subkey, value: value)
    }
  }
  
  func setCachedItemsDictWithoutLock(cachedItemsDict: inout CachedItemsDict, key: String, subkey: String, value: Any) {
      if cachedItemsDict[key] == nil {
        cachedItemsDict[key] = [:]
      }
      cachedItemsDict[key]?[subkey] = value
      self.flushCachedItemsDictToDisk(cachedItemsDict)
  }
  
  func removeCachedItemsDict(forKey key: String) {
    cachedItemsDictLockWrite { [weak self] (cachedItemsDict) -> Void in
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
  
  func cachedItemsDictLockWrite<Result>(closure: @escaping (inout CachedItemsDict) -> Result?) -> Result? {
    // Get result throught write lock.
    let result = cachedItemsDictLock.writeLock(closure)
    
    // Publish DownloadedURLs.
    publishDownloadedURLs()
    
    return result
  }
  
  func publishDownloadedURLs() {
    let cachedFileHttpURLs = self.cachedFileHttpURLs().map { URL(string: $0)! }
    downloadedObserverManager?.publishDownloadedURLs(cachedFileHttpURLs)
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
  
  /**
   Returns HTTP URL strings of downloaded files.
   */
  func cachedFileHttpURLs() -> [String] {
    return cachedItemsDictLock.readLock { (cachedItemsDict) -> [String] in
      cachedItemsDict
        .keys
        .sorted(by: { (key0, key1) -> Bool in
          // Sort HTTP URLs by modifiedDate.
          let modifiedDate0 = cachedItemsDict[key0]?[CacheConstant.kFileModifiedDate] as? Date
          let modifiedDate1 = cachedItemsDict[key1]?[CacheConstant.kFileModifiedDate] as? Date
          return modifiedDate1!.timeIntervalSince(modifiedDate0!)  > 0
        })
        .compactMap {
        return cachedItemsDict[$0]?[CacheConstant.kHttpUrlString] as? String
      }
    } ?? []
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
    let removeFileURLs = cachedItemsDictLockWrite { (cachedItemsDict: inout CachedItemsDict) -> [URL] in
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
      
      let removeFileURLs = cachedItemsDictLockWrite { (cachedItemsDict: inout CachedItemsDict) -> [URL] in
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
