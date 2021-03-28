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
  
  internal typealias TransformMetadataToCachedData = (_ data: Data) -> DataType?
  
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
  private(set) var ioQueue: DispatchQueue

  private var fileManager: FileManager
  private var transformMetadataToCachedData: TransformMetadataToCachedData

  public init(maxCacheAge: TimeInterval,
              maxCacheSize: Int,
              cacheFolderName: String,
              transformMetadataToCachedData: @escaping TransformMetadataToCachedData) {
    self.maxCacheAge = maxCacheAge
    self.maxCacheSize = maxCacheSize
    self.cacheFolderName = cacheFolderName
    self.fileManager = FileManager()
    self.transformMetadataToCachedData = transformMetadataToCachedData
        
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
}

// MARK: - Set / Get Cache file
  
extension CZDiskCacheManager {
  
  public func setCacheFile(withUrl url: URL, data: Data?) {
    guard let data = data.assertIfNil else { return }
    let (fileURL, cacheKey) = getCacheFileInfo(forURL: url)
    
    // Disk cache
    ioQueue.async(flags: .barrier) { [weak self] in
      guard let `self` = self else { return }
      do {
        try data.write(to: fileURL)
        self.setCachedItemsDictForNewURL(url, fileSize: data.count)
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
  func setCachedItemsDictForNewURL(_ httpURL: URL, fileSize: Int) {
    let (_, cacheKey) = getCacheFileInfo(forURL: httpURL)
    setCachedItemsDict(key: cacheKey, subkey: CacheConstant.kHttpUrlString, value: httpURL.absoluteString)
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
    dbgPrint("CZDiskCacheManager.cachedFileURL() - cacheFileURLs = \(cachedFileURLs())")
    
    let cacheFileInfo = getCacheFileInfo(forURL: httpURL)
    let fileURL = cacheFileInfo.fileURL
    let isExisting = urlExistsInCache(httpURL)
    return (fileURL, isExisting)
  }
  
  func cachedFileURLs() -> [String] {
    return cachedItemsDictLock.readLock { (cachedItemsDict) -> [String] in
      cachedItemsDict.keys.compactMap {
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
