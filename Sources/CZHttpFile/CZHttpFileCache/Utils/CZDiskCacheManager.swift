import UIKit
import CZUtils

public typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
public typealias CleanDiskCacheCompletion = () -> Void
public typealias SetCacheFileCompletion = () -> Void
internal typealias CachedItemsDict = [String: [String: Any]]

internal enum CZDiskCacheManagerConstant {
  /// Debounce interval - write cachedItemsDict to disk at most once every 5 secs.
  static var debounceTaskSchedulerGap: TimeInterval = 5
}

/**
 Manager that maintains the disk cache including file read/write and cachedItemsDict.
 */
internal class CZDiskCacheManager<DataType>: NSObject {

  private(set) lazy var cacheFolderHelper: CZCacheFolderHelper = {
    return CZCacheFolderHelper(cacheFolderName: cacheFolderName)
  }()
  
  internal typealias TransformMetadataToCachedData = (_ data: Data) -> DataType?
  
  private var cacheFolderName: String
  
  private lazy var cachedItemsDictFileURL: URL = {
    return URL(fileURLWithPath: cacheFolderHelper.cacheFolder + CacheConstant.kCachedItemsDictFile)
  }()
  
  /// `cachedItems` maintains cached file size, create date. It's mainly used for:  1. cache clearing 2. publishDownloadedURLs().
  lazy var cachedItemsDictLock: CZSimpleMutexLock<CachedItemsDict>? = {
    guard shouldEnableCachedItemsDict else {
      return nil
    }
    let cachedItemsDict: CachedItemsDict = loadCachedItemsDict() ?? [:]
    return CZSimpleMutexLock(cachedItemsDict)
  }()
  
  var currentCacheSize: Int {
    return cachedItemsDictLock?.readLock { [weak self] (cachedItemsDict: CachedItemsDict) -> Int in
      guard let `self` = self else {return 0}
      return self.getSizeWithoutLock(cachedItemsDict: cachedItemsDict)
    } ?? 0
  }
  
  let maxCacheAge: TimeInterval
  let maxCacheSize: Int
  let ioQueue: DispatchQueue
  let shouldEnableCachedItemsDict: Bool
  private(set) weak var downloadedObserverManager: CZDownloadedObserverManager?

  private let transformMetadataToCachedData: TransformMetadataToCachedData
  
  /// The debouncing task scheduler that write cachedItems to disk every `debounceTaskSchedulerGap` seconds to improve the performance.
  private var debounceTaskScheduler: DebounceTaskScheduler?
  
  // MARK: - Initializer
    
  /// Initialization of CZDiskCacheManager.
  ///
  /// - Parameters:
  ///   - shouldEnableCachedItemsDict: Indicates whether to save cached file information. e.g. url, size. Defaults to false.
  ///     false for CZWebImage. true for CZHttpFile - large files.
  public init(maxCacheAge: TimeInterval,
              maxCacheSize: Int,
              cacheFolderName: String,
              shouldEnableCachedItemsDict: Bool = false,
              transformMetadataToCachedData: @escaping TransformMetadataToCachedData,
              downloadedObserverManager: CZDownloadedObserverManager? = nil) {
    self.maxCacheAge = maxCacheAge
    self.maxCacheSize = maxCacheSize
    self.cacheFolderName = cacheFolderName
    self.shouldEnableCachedItemsDict = shouldEnableCachedItemsDict
    self.downloadedObserverManager = downloadedObserverManager
    self.transformMetadataToCachedData = transformMetadataToCachedData
    if shouldEnableCachedItemsDict {
      self.debounceTaskScheduler = DebounceTaskScheduler(interval: CZDiskCacheManagerConstant.debounceTaskSchedulerGap)
    }
    
    self.ioQueue = DispatchQueue(
      label: CacheConstant.ioQueueLabel,
      //qos: .userInitiated,
      qos: .default,
      attributes: .concurrent)
    
    super.init()    
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
    return cachedItemsDictLock?.readLock { [weak self] (cachedItemsDict) -> Bool? in
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
    
    // Disk cache.
    // The reason to abandon `.barrier` flag: it blocks other operations if any writing is on going. (Files writing is discrete: mostly won't conflict)
    // [Won't fix] It won't cause issues:
    // 1). As data.write(to:) is called with .atomic option, which won't write the target file
    // with temp file if writing fails.
    // 2). If writing fails, the downloader will download the file again as it doesn't find file in mem / disk cache.
    // https://github.com/geekaurora/CZHttpFile/issues/38
    // ioQueue.async(flags: .barrier) { [weak self] in
    ioQueue.async { [weak self] in
      guard let `self` = self else { return }
      do {
        self.setCachedItemsDictForNewURL(url, fileSize: data.count)
        completeSetCachedItemsDict?()
        // * Write downloaded file to disk.
        // `.atomic`: If write succeeds, moves the temporary file to its final location.
        try data.write(to: fileURL, options: [.atomic])
        completeSaveCachedFile?()
      } catch {
        assertionFailure("Failed to write file - \(fileURL). Error - \(error.localizedDescription)")
      }
    }
  }
  
  public func getCachedFile(withUrl url: URL,
                            completion: @escaping (DataType?) -> Void)  {
    // Read data from disk cache.
    // Note: should async() to avoid blocking main thread.
    // self.ioQueue.sync
    self.ioQueue.async { [weak self] in
      guard let `self` = self else { return }
      let (fileURL, cacheKey) = self.getCacheFileInfo(forURL: url)
      
      if let data = try? Data(contentsOf: fileURL),
         let image = self.transformMetadataToCachedData(data).assertIfNil {
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
    
    cachedItemsDictLockWrite(isAsync: true) { [weak self] (cachedItemsDict) -> Void in
      guard let `self` = self else {
        return        
      }
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kHttpUrlString, value: httpURL.absoluteString)
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kFileModifiedDate, value: NSDate())
      self.setCachedItemsDictWithoutLock(cachedItemsDict: &cachedItemsDict, key: cacheKey, subkey: CacheConstant.kFileSize, value: fileSize)      
    }
  }
   
  func setCachedItemsDict(key: String,
                          subkey: String,
                          value: Any,
                          skipIfKeyNotExists: Bool = false) {
    cachedItemsDictLockWrite(isAsync: true) { [weak self] (cachedItemsDict) -> Void in
      guard let `self` = self else { return }
      self.setCachedItemsDictWithoutLock(
        cachedItemsDict: &cachedItemsDict,
        key: key,
        subkey: subkey,
        value: value,
        skipIfKeyNotExists: skipIfKeyNotExists)
    }
  }
  
  func setCachedItemsDictWithoutLock(cachedItemsDict: inout CachedItemsDict,
                                     key: String,
                                     subkey: String,
                                     value: Any,
                                     skipIfKeyNotExists: Bool = false) {
      if cachedItemsDict[key] == nil {
        // Skip writing if the corresponding key doesn't exist.
        guard !skipIfKeyNotExists else {
          return
        }
        cachedItemsDict[key] = [:]
      }
      cachedItemsDict[key]?[subkey] = value
      self.flushCachedItemsDictToDisk(cachedItemsDict)
  }
  
  /**
   - Note: For tests only!
   
   Should call `cachedItemsDictLock.readLock` to read cachedItemsDict for data consistency.
   */
  func getCachedItemsDict() -> CachedItemsDict {
    return cachedItemsDictLock?.readLock { (cachedItemsDict) -> CachedItemsDict? in
      cachedItemsDict
    } ?? [:]
  }
  
//  func removeCachedItemsDict(forKey key: String) {
//    cachedItemsDictLockWrite { [weak self] (cachedItemsDict) -> Void in
//      guard let `self` = self else { return }
//      cachedItemsDict.removeValue(forKey: key)
//      self.flushCachedItemsDictToDisk(cachedItemsDict)
//    }
//  }
//
//  func removeCachedItemsDict(forUrl url: URL) {
//    let cacheFileInfo = getCacheFileInfo(forURL: url)
//    removeCachedItemsDict(forKey: cacheFileInfo.cacheKey)
//  }
  
  func flushCachedItemsDictToDisk(_ cachedItemsDict: CachedItemsDict) {
    guard shouldEnableCachedItemsDict else {
      return
    }
    // Write cachedItemsDict to disk asynchronously with `debounceTaskScheduler`: only write once every 5s.
    debounceTaskScheduler?.schedule { [weak self] in
      self?.flushCachedItemsDictToDiskWithoutScheduler(cachedItemsDict)
    }
    // flushCachedItemsDictToDiskWithoutScheduler(cachedItemsDict)
  }
  
  func flushCachedItemsDictToDiskWithoutScheduler(_ cachedItemsDict: CachedItemsDict) {
    dbgPrintWithFunc(self, "flushCachedItemsDictToDiskWithoutScheduler()")
    (cachedItemsDict as NSDictionary).write(to: cachedItemsDictFileURL, atomically: true)
  }
  
  func cachedItemsDictLockWrite<Result>(isAsync: Bool = false,
                                        closure: @escaping (inout CachedItemsDict) -> Result?) -> Result? {
    guard shouldEnableCachedItemsDict else {
      return nil
    }
    // Get result through write lock.
    let result = cachedItemsDictLock?.writeLock(isAsync: isAsync, closure)
    
    // Publish DownloadedURLs.
    // publishDownloadedURLs()
    
    return result
  }
  
  // MARK: - Publish state
  
  var downloadedURLs: [URL] {
    return self.cachedFileHttpURLs().map { URL(string: $0)! }
  }
  
  func publishDownloadedURLs() {
    downloadedObserverManager?.publishDownloadedURLs(self.downloadedURLs)
  }
}

// MARK: - Clean Cache

internal extension CZDiskCacheManager {
  
  /// Force to clear all disk cache.
  func clearCache(completion: CleanDiskCacheCompletion? = nil) {
    // Delete the cache directory.
    ioQueue.async(flags: .barrier) { [weak self] in
      guard let `self` = self else { return }
      CZFileHelper.removeDirectory(path: self.cacheFolderHelper.cacheFolder, createDirectoryAfterDeletion: true)
    }
    
    self.cleanDiskCache { (itemInfo: [String : Any]) -> Bool in
      return true
    } completion: {
      MainQueueScheduler.safeAsync {
        completion?()
      }
    }
  }
  
  func cleanDiskCacheIfNeeded(completion: CleanDiskCacheCompletion? = nil) {
    guard shouldEnableCachedItemsDict else {
      return
    }
    
    // 1. Clean disk by age.
    if self.maxCacheAge != -1 {
      let currDate = Date()
      cleanDiskCache { (itemInfo: [String : Any]) -> Bool in
        guard let modifiedDate = itemInfo[CacheConstant.kFileModifiedDate] as? Date else {
          return false
        }
        return currDate.timeIntervalSince(modifiedDate) > self.maxCacheAge
      }
    }
    
    // 2. Clean disk by maxSize setting: based on visited date - simple LRU.
    if self.maxCacheSize != -1 && self.currentCacheSize > self.maxCacheSize {
      dbgPrint("\n\n\n[Cache][CleanUp] Cleaning cache .. currentCacheSize = \(currentCacheSize), maxCacheSize = \(maxCacheSize)\n\n\n")
      
      let expectedCacheSize = self.maxCacheSize / 2
      let expectedReduceSize = self.currentCacheSize - expectedCacheSize
      
      var removedFilesSize: Int = 0
      
      self.cleanDiskCache(
        sortCachedItemsDictClosure: { (keyValue1: (key: String, value: [String : Any]),
                                       keyValue2: (key: String, value: [String : Any])) -> Bool in
          // Sort files with last visted date
          if let modifiedDate1 = keyValue1.value[CacheConstant.kFileModifiedDate] as? Date,
             let modifiedDate2 = keyValue2.value[CacheConstant.kFileModifiedDate] as? Date {
            return modifiedDate1.timeIntervalSince(modifiedDate2) < 0
          } else {
            fatalError()
          }
        },
        
        shouldRemoveItemClosure: { (itemInfo: [String : Any]) -> Bool in
          if removedFilesSize >= expectedReduceSize {
            return false
          } else {
            let oneFileSize = (itemInfo[CacheConstant.kFileSize] as? Int) ?? 0
            removedFilesSize += oneFileSize
            return true
          }
        })
    }
    
    // TODO: call completion after removing files.
    completion?()
  }
      
  /**
   Clean cache by removing files and items from CachedItemsDict with input params.
   
   - Parameters:
     - sortCachedItemsDictClosure: Closure that  sorts scachedItemsDict.
     - shouldRemoveItemClosure: Closure that returns whether to remove item with its info dictionary.
   */
  typealias CachedItemsDictKeyValueTuple = (key: String, value: [String : Any])
  typealias SortCachedItemsDictClosure = (CachedItemsDictKeyValueTuple, CachedItemsDictKeyValueTuple) -> Bool
  
  private func cleanDiskCache(sortCachedItemsDictClosure: SortCachedItemsDictClosure? = nil,
                              shouldRemoveItemClosure: @escaping ([String: Any]) -> Bool,
                              completion: CleanDiskCacheCompletion? = nil) {
    // 1. Remove items from cachedItemsDict.
    let removeFileURLs = cachedItemsDictLockWrite { (cachedItemsDict: inout CachedItemsDict) -> [URL] in
      var removedKeys = [String]()
      
      // Sort cachedItemsDict if `sortCachedItemsDictClosure` isn't nil, otherwise keep the original order.
      let sortedItemsInfo: [CachedItemsDictKeyValueTuple] = {
        guard let sortCachedItemsDictClosure = sortCachedItemsDictClosure else {
          return cachedItemsDict.map { (key: $0, value: $1) }
        }
        return cachedItemsDict.sorted(by: sortCachedItemsDictClosure)
      }()
      
      // Loop through keys / values of cachedItemsDict: decide whether to remove the `key`.
      for (key, value) in sortedItemsInfo {
        if shouldRemoveItemClosure(value) {
          dbgPrint("[Cache][CleanUp] Cleaning cache .. key = \(key)")
          removedKeys.append(key)
          cachedItemsDict.removeValue(forKey: key)
        }
      }
      self.flushCachedItemsDictToDisk(cachedItemsDict)
      let removeFileURLs = removedKeys.compactMap { self.cacheFileURL(forKey: $0) }
      return removeFileURLs
    }
    
    guard !(removeFileURLs?.isEmpty ?? true) else {
      return
    }
      
    // 2. Remove corresponding files from disk.
    self.ioQueue.async(flags: .barrier) {
      removeFileURLs?.forEach {
        CZFileHelper.removeFile($0)
      }
      
      // 3. Call completion if applicable.
      completion?()
    }
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
    return cachedItemsDictLock?.readLock { (cachedItemsDict) -> [String] in
      cachedItemsDict
        .keys
        .sorted(by: { (key0, key1) -> Bool in
          // Sort URLs by modifiedDate.
          guard let modifiedDate0 = cachedItemsDict[key0]?[CacheConstant.kFileModifiedDate] as? Date,
                let modifiedDate1 = cachedItemsDict[key1]?[CacheConstant.kFileModifiedDate] as? Date else {
            return false
          }
          return modifiedDate1.timeIntervalSince(modifiedDate0)  > 0
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

// MARK: - Private methods

private extension CZDiskCacheManager {
  func loadCachedItemsDict() -> CachedItemsDict? {
    return NSDictionary(contentsOf: cachedItemsDictFileURL) as? CachedItemsDict
  }
}
