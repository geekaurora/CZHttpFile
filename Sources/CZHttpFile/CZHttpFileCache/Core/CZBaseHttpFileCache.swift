import UIKit
import CZUtils

/**
 Thread safe local cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy.
 
 ### Note
 
 - `DataType` is Class type of decoded CachedData from original `Data`. e.g. UIImage, Data.
 
 ### Usage
 
 1. Initializer
 ```
 super.init(
       transformMetadataToCachedData: Self.transformMetadataToCachedData)
 ```
 
 2. override `cacheCost` to calculate data cost for memCache.
 ```
 override func cacheCost(forImage image: AnyObject) -> Int {
   guard let image = (image as? UIImage).assertIfNil else {
     return 0
   }
   return Int(image.size.height * image.size.width * image.scale * image.scale)
  }
 ```
 
 3. Define `transformMetadataToCachedData` closure to transforms from `Data` to  desired class type e.g. UIImage.
 ```
 static func transformMetadataToCachedData(_ data: Data?) -> UIImage?
 ```
 
 4. Override `cacheFolderName`
 - Note: should override `cacheFolderName` to avoid conflicts. e.g. CacheItenInfo.plist.
 
 ```
 public var cacheFolderName: String {
   return "CZCache"
 }
 ```
 */
public enum CacheConstant {
  public static let kMaxFileAge: TimeInterval = 60 * 24 * 60 * 60
  public static let kMaxCacheSize: Int = 500 * 1024 * 1024
  public static let kCachedItemsInfoFile = "cachedItemsInfo.plist"
  public static let kFileModifiedDate = "modifiedDate"
  public static let kFileVisitedDate = "visitedDate"
  public static let kFileSize = "size"
  public static let ioQueueLabel = "com.tony.cache.ioQueue"
}

/**
 Base class of http file cache.
 
 Constraining `DataType` with `NSObjectProtocol` because NSCache requires its Value type to be Class.
 */
open class CZBaseHttpFileCache<DataType: NSObjectProtocol>: NSObject {
  public typealias CleanDiskCacheCompletion = () -> Void
  
  public var cacheFolderName: String {
    return "CZBaseHttpFileCache"
  }
  
  private var ioQueue: DispatchQueue
  private var memCache: NSCache<NSString, DataType>
  private var fileManager: FileManager
  private var operationQueue: OperationQueue
  private var hasCachedItemsInfoToFlushToDisk: Bool = false
  internal typealias CachedItemsInfo = [String: [String: Any]]
  
  private lazy var cacheFileManager: CZCacheFileManager = {
    return CZCacheFileManager(cacheFolderName: cacheFolderName)
  }()
  private lazy var cachedItemsInfoFileURL: URL = {
    return URL(fileURLWithPath: cacheFileManager.cacheFolder + CacheConstant.kCachedItemsInfoFile)
  }()
  private lazy var cachedItemsInfoLock: CZMutexLock<CachedItemsInfo> = {
    let cachedItemsInfo: CachedItemsInfo = loadCachedItemsInfo() ?? [:]
    return CZMutexLock(cachedItemsInfo)
  }()
    
  private(set) var maxCacheAge: TimeInterval
  private(set) var maxCacheSize: Int
  
  public init(maxCacheAge: TimeInterval = CacheConstant.kMaxFileAge,
              maxCacheSize: Int = CacheConstant.kMaxCacheSize) {
    operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 60
    
    ioQueue = DispatchQueue(label: CacheConstant.ioQueueLabel,
                            qos: .userInitiated,
                            attributes: .concurrent)
    fileManager = FileManager()
    
    // Memory cache
    memCache = NSCache()
    memCache.countLimit = 1000
    memCache.totalCostLimit = 1000 * 1024 * 1024
    
    self.maxCacheAge = maxCacheAge
    self.maxCacheSize = maxCacheSize
    super.init()
    
    // Clean cache
    cleanDiskCacheIfNeeded()
  }
  
  public func setCacheFile(withUrl url: URL, data: Data?) {
    guard let data = data.assertIfNil else { return }
    let (fileURL, cacheKey) = getCacheFileInfo(forURL: url)
    // Mem cache
    // `transformMetadataToCachedData` is to transform `Data` to real Data type.
    // e.g. let image = UIImage(data: data)
    if let image = transformMetadataToCachedData(data) {
      setMemCache(image: image, forKey: cacheKey)
    }
    
    // Disk cache
    ioQueue.async(flags: .barrier) { [weak self] in
      guard let `self` = self else { return }
      do {
        try data.write(to: fileURL)
        self.setCachedItemsInfo(key: cacheKey, subkey: CacheConstant.kFileModifiedDate, value: NSDate())
        self.setCachedItemsInfo(key: cacheKey, subkey: CacheConstant.kFileVisitedDate, value: NSDate())
        self.setCachedItemsInfo(key: cacheKey, subkey: CacheConstant.kFileSize, value: data.count)
      } catch {
        assertionFailure("Failed to write file. Error - \(error.localizedDescription)")
      }
    }
  }
  
  public func getCachedFile(withUrl url: URL,
                            completion: @escaping (DataType?) -> Void)  {
    let (fileURL, cacheKey) = self.getCacheFileInfo(forURL: url)
    // Read data from mem cache
    var image = self.getMemCache(forKey: cacheKey)
    
    // Read data from disk cache
    if image == nil {
      image = self.ioQueue.sync {
        if let data = try? Data(contentsOf: fileURL),
           // let image = UIImage(data: data)
           let image = transformMetadataToCachedData(data).assertIfNil {
          // Update last visited date
          self.setCachedItemsInfo(key: cacheKey, subkey: CacheConstant.kFileVisitedDate, value: NSDate())
          // Set mem cache after loading data from local drive
          self.setMemCache(image: image, forKey: cacheKey)
          return image
        }
        return nil
      }
    }
    // Completion callback
    MainQueueScheduler.sync {
      completion(image)
    }
  }
  
  var size: Int {
    return cachedItemsInfoLock.readLock { [weak self] (cachedItemsInfo: CachedItemsInfo) -> Int in
      guard let `self` = self else {return 0}
      return self.getSizeWithoutLock(cachedItemsInfo: cachedItemsInfo)
    } ?? 0
  }
  
  // MARK: - Overriden methods
  
  internal func transformMetadataToCachedData(_ data: Data) -> DataType? {
    fatalError("\(#function) should be overriden in subclass - \(type(of: self)).")
  }
  
  internal func cacheCost(forImage image: DataType) -> Int {
    fatalError("\(#function) should be overriden in subclass - \(type(of: self)).")
  }
}

// MARK: - Private methods

internal extension CZBaseHttpFileCache {
  func getSizeWithoutLock(cachedItemsInfo: CachedItemsInfo) -> Int {
    var totalCacheSize: Int = 0
    for (_, value) in cachedItemsInfo {
      let oneFileSize = (value[CacheConstant.kFileSize] as? Int)  ?? 0
      totalCacheSize += oneFileSize
    }
    return totalCacheSize
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
  
  func getMemCache(forKey key: String) -> DataType? {
    return memCache.object(forKey: NSString(string: key))
  }
  
  func setMemCache(image: DataType, forKey key: String) {
    let cost = cacheCost(forImage: image)
    memCache.setObject(
      image,
      forKey: NSString(string: key),
      cost: cost)
  }
  
  public typealias CacheFileInfo = (fileURL: URL, cacheKey: String)
  public func getCacheFileInfo(forURL url: URL) -> CacheFileInfo {
    let urlString = url.absoluteString
    let cacheKey = urlString.MD5 + urlString.fileType(includingDot: true)
    let fileURL = URL(fileURLWithPath: cacheFileManager.cacheFolder + cacheKey)
    return (fileURL: fileURL, cacheKey: cacheKey)
  } 
  
  func cacheFileURL(forKey key: String) -> URL {
    return URL(fileURLWithPath: cacheFileManager.cacheFolder + key)
  }
  
  func cleanDiskCacheIfNeeded(completion: CleanDiskCacheCompletion? = nil){
    let currDate = Date()
    
    // 1. Clean disk by age
    let removeFileURLs = cachedItemsInfoLock.writeLock { (cachedItemsInfo: inout CachedItemsInfo) -> [URL] in
      var removedKeys = [String]()
      
      // Remove key if its fileModifiedDate exceeds maxCacheAge
      cachedItemsInfo.forEach { (keyValue: (key: String, value: [String : Any])) in
        if let modifiedDate = keyValue.value[CacheConstant.kFileModifiedDate] as? Date,
           currDate.timeIntervalSince(modifiedDate) > self.maxCacheAge {
          removedKeys.append(keyValue.key)
          cachedItemsInfo.removeValue(forKey: keyValue.key)
        }
      }
      self.flushCachedItemsInfoToDisk(cachedItemsInfo)
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
    if self.size > self.maxCacheSize {
      let expectedCacheSize = self.maxCacheSize / 2
      let expectedReduceSize = self.size - expectedCacheSize
      
      let removeFileURLs = cachedItemsInfoLock.writeLock { (cachedItemsInfo: inout CachedItemsInfo) -> [URL] in
        // Sort files with last visted date
        let sortedItemsInfo = cachedItemsInfo.sorted { (keyValue1: (key: String, value: [String : Any]),
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
          cachedItemsInfo.removeValue(forKey: key)
          removedKeys.append(key)
          let oneFileSize = (value[CacheConstant.kFileSize] as? Int) ?? 0
          removedFilesSize += oneFileSize
        }
        self.flushCachedItemsInfoToDisk(cachedItemsInfo)
        return removedKeys.compactMap {self.cacheFileURL(forKey: $0)}
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
