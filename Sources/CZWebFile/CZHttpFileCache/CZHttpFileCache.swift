import Foundation
import CZUtils

/**
 Thread safe local cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy.
 
 - Note: CachedData Class type is `NSData`.
 */
class CZHttpFileCache: CZBaseHttpFileCache<NSData> {
  public static let shared = CZHttpFileCache()
  
  // MARK: - Override methods
  
  /**
   Data transformer that transforms from `data` to  NSData.
   */
  override func transformMetadataToCachedData(_ data: Data) -> NSData? {
    return data as NSData
  }
  
  override func cacheCost(forImage image: NSData) -> Int {
    return image.count
  }
}
