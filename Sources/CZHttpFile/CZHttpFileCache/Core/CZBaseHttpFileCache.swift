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
  public static let kCachedItemsDictFile = "cachedItemsDict.plist"
  public static let kFileModifiedDate = "modifiedDate"
  public static let kFileVisitedDate = "visitedDate"
  public static let kFileHttpUrl = "url"
  public static let kFileSize = "size"
  public static let ioQueueLabel = "com.tony.cache.ioQueue"
}

/**
 Base class of http file cache.
 
 Constraining `DataType` with `NSObjectProtocol` because NSCache requires its Value type to be Class.
 */
open class CZBaseHttpFileCache<DataType: NSObjectProtocol>: NSObject {
  
  public var cacheFolderName: String {
    return "CZBaseHttpFileCache"
  }
  
  private(set) var ioQueue: DispatchQueue
  private var memCache: NSCache<NSString, DataType>
  private var operationQueue: OperationQueue
  
  private lazy var diskCacheManager: CZDiskCacheManager<DataType> = {
    let diskCacheManager = CZDiskCacheManager(
      maxCacheAge: maxCacheAge,
      maxCacheSize: maxCacheSize,
      cacheFolderName: cacheFolderName,
      httpFileCache: self)
    return diskCacheManager
  }()
  
  private(set) var maxCacheAge: TimeInterval
  private(set) var maxCacheSize: Int
  
  public init(maxCacheAge: TimeInterval = CacheConstant.kMaxFileAge,
              maxCacheSize: Int = CacheConstant.kMaxCacheSize) {
    operationQueue = OperationQueue()
    operationQueue.maxConcurrentOperationCount = 60
    
    ioQueue = DispatchQueue(
      label: CacheConstant.ioQueueLabel,
      qos: .userInitiated,
      attributes: .concurrent)
    
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
    let (_, cacheKey) = diskCacheManager.getCacheFileInfo(forURL: url)
    
    // Mem cache
    // `transformMetadataToCachedData` is to transform `Data` to real Data type.
    // e.g. let image = UIImage(data: data)
    if let image = transformMetadataToCachedData(data) {
      setMemCache(image: image, forKey: cacheKey)
    }
    
    // Disk cache
    diskCacheManager.setCacheFile(withUrl: url, data: data)
  }
  
  public func getCachedFile(withUrl url: URL,
                            completion: @escaping (DataType?) -> Void)  {
    let (fileURL, cacheKey) = diskCacheManager.getCacheFileInfo(forURL: url)
    // Read data from mem cache
    var image = self.getMemCache(forKey: cacheKey)
    
    // Read data from disk cache
    if image == nil {
      image = self.ioQueue.sync {
        if let data = try? Data(contentsOf: fileURL),
           // let image = UIImage(data: data)
           let image = transformMetadataToCachedData(data).assertIfNil {
          // Update last visited date
          self.diskCacheManager.setCachedItemsDict(key: cacheKey, subkey: CacheConstant.kFileVisitedDate, value: NSDate())
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
    return diskCacheManager.totalCachedFileSize
  }
  
  // MARK: - Overriden methods
  
  internal func transformMetadataToCachedData(_ data: Data) -> DataType? {
    fatalError("\(#function) should be overriden in subclass - \(type(of: self)).")
  }
  
  internal func cacheCost(forImage image: DataType) -> Int {
    fatalError("\(#function) should be overriden in subclass - \(type(of: self)).")
  }
}

// MARK: - Helper methods

public extension CZBaseHttpFileCache {
  /**
   Returns cached file URL if has been downloaded, otherwise nil.
   */
  func cachedFileURL(forURL httpURL: URL?) -> (fileURL: URL?, isExisting: Bool) {
    return diskCacheManager.cachedFileURL(forURL: httpURL)
  }
  
  func getCacheFileInfo(forURL url: URL) -> CacheFileInfo {
    return diskCacheManager.getCacheFileInfo(forURL: url)
  }  
}

// MARK: - Private methods

internal extension CZBaseHttpFileCache {
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
  
  func cleanDiskCacheIfNeeded(completion: CleanDiskCacheCompletion? = nil) {
    diskCacheManager.cleanDiskCacheIfNeeded(completion: completion)    
  }
  
}
