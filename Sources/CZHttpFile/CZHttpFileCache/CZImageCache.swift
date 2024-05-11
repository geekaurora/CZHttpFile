import UIKit
import CZUtils

/**
 Thread safe local image cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy.
 
 - Note: CachedData Class type is `UIImage`.
 */
public class CZImageCache: CZBaseHttpFileCache<UIImage> {
  public static let shared = CZImageCache()
  
  // MARK: - Override methods

  public override var cacheFolderName: String {
    return "CZImageCache"
  }
  
  /**
   Data transformer that transforms from `data` to  UIImage.
   */
  public override func transformDataToModel(_ data: Data) -> UIImage? {
    let image = UIImage(data: data)
    return image
  }
  
  public override func cacheCost(forModel image: UIImage) -> Int {
    return Int(image.size.height * image.size.width * image.scale * image.scale)
  }
}
