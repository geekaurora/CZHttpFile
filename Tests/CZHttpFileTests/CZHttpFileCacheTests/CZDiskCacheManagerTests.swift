import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZDiskCacheManagerTests: XCTestCase {
  private enum MockData {
    static let key = "929832737212"
    static let testSize = 16232
    static let testUrl = URL(string: "http://www.test.com/some_file.jpg")!
    static let dict: [String: AnyHashable] = [
      "a": "sdlfjas",
      "c": "sdlksdf",
      "b": "239823sd",
      "d": 189298723,
    ]
  }
  var httpFileCache: CZHttpFileCache!
  
  override class func setUp() {
    let httpFileCache = CZHttpFileCache()
    httpFileCache.clearCache()
    Thread.sleep(forTimeInterval: 0.1)
  }
  
  override class func tearDown() {
    let httpFileCache = CZHttpFileCache()
    httpFileCache.clearCache()
    Thread.sleep(forTimeInterval: 0.1)
  }
  
  override func setUp() {
    httpFileCache = CZHttpFileCache()
    // httpFileCache.removeCachedItemsDict(forUrl: MockData.testUrl)
    Thread.sleep(forTimeInterval: 0.01)
  }
  
  /*
  public enum CacheConstant {
    public static let kFileModifiedDate = "modifiedDate"
    public static let kFileVisitedDate = "visitedDate"
    public static let kHttpUrlString = "url"
    public static let kFileSize = "size"
    public static let ioQueueLabel = "com.tony.cache.ioQueue"
  }
 */
  
  func testSetCachedItemsDict1() {
    // setCachedItemsDict.
    httpFileCache.diskCacheManager.setCachedItemsDict(
      key: MockData.key,
      subkey: CacheConstant.kFileSize,
      value: MockData.testSize)
    
    // Verify: getCachedItemsDict.
    let cachedItemsDict = httpFileCache.diskCacheManager.getCachedItemsDict()
    let actualValue = cachedItemsDict[MockData.key]?[CacheConstant.kFileSize] as? Int
    XCTAssertEqual(
      actualValue,
      MockData.testSize,
      "Incorrect value! expected = \(MockData.testSize), \nactual = \(actualValue)"
    )
  }
  
  func testSetCachedItemsDict2_ReadFromCache() {
    // Verify from cache: getCachedItemsDict.
    let cachedItemsDict = httpFileCache.diskCacheManager.getCachedItemsDict()
    let actualValue = cachedItemsDict[MockData.key]?[CacheConstant.kFileSize] as? Int
    XCTAssertEqual(
      actualValue,
      MockData.testSize,
      "Incorrect value! expected = \(MockData.testSize), \nactual = \(actualValue)"
    )
  }
  
}
