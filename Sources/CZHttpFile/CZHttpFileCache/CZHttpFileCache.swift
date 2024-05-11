import Foundation
import CZUtils

/**
 Thread safe local file cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy.
 
 - Note: CachedData Class type is `NSData`.
 */
public class CZHttpFileCache: CZBaseHttpFileCache<NSData> {

  // MARK: - Override methods
  
  public override var cacheFolderName: String {
    return "CZHttpFileCache"
  }
  
  /**
   Data transformer that transforms from `data` to  NSData.
   */
  public override func transformDataToModel(_ data: Data) -> NSData? {
    return data as NSData
  }
  
  public override func cacheCost(forModel image: NSData) -> Int {
    return image.count
  }
}
