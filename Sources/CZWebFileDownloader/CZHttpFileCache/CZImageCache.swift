import UIKit
import CZUtils
import CZHttpFileCache

/**
 Thread safe local image cache backed by DispatchQueue mutex lock/LRU queue, supports maxFileAge/maxCacheSize purging strategy.
 
 - Note: CachedData Class type is `UIImage`.
 */
public class CZImageCache: CZBaseHttpFileCache<UIImage> {
  public static let shared = CZImageCache()
  
  // MARK: - Override methods
  
  /**
   Data transformer that transforms from `data` to  UIImage.
   */
  override func transformMetadataToCachedData(_ data: Data) -> UIImage? {
    let image = UIImage(data: data)
    return image
  }
  
  override func cacheCost(forImage image: UIImage) -> Int {
    return Int(image.size.height * image.size.width * image.scale * image.scale)
  }
}
