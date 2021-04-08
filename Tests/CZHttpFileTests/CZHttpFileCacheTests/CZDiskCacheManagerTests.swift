import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZDiskCacheManagerTests: XCTestCase {
  private enum MockData {
    static let key = "929832737212"
    static let testUrl = URL(string: "http://www.test.com/some_file.jpg")!
    static let dict: [String: AnyHashable] = [
      "a": "sdlfjas",
      "c": "sdlksdf",
      "b": "239823sd",
      "d": 189298723,
    ]
  }
  var httpFileCache: CZHttpFileCache!
  
  override func setUp() {
    httpFileCache = CZHttpFileCache()
    // httpFileCache.removeCachedItemsDict(forUrl: MockData.testUrl)
    Thread.sleep(forTimeInterval: 0.01)
  }
  
  /*
  public enum CacheConstant {
    public static let kMaxFileAge: TimeInterval = 60 * 24 * 60 * 60
    public static let kMaxCacheSize: Int = 500 * 1024 * 1024
    public static let kCachedItemsDictFile = "cachedItemsDict.plist"
    public static let kFileModifiedDate = "modifiedDate"
    public static let kFileVisitedDate = "visitedDate"
    public static let kHttpUrlString = "url"
    public static let kFileSize = "size"
    public static let ioQueueLabel = "com.tony.cache.ioQueue"
  }
 */
  
  func testSetCachedItemsDict() {
    // setCachedItemsDict.
    httpFileCache.diskCacheManager.setCachedItemsDict(
      key: MockData.key,
      subkey: CacheConstant.kHttpUrlString,
      value: MockData.testUrl.absoluteString)
    
    // Verify: getCachedItemsDict.
    let cachedItemsDict = httpFileCache.diskCacheManager.getCachedItemsDict()
    let actualUrl = cachedItemsDict[MockData.key]?[CacheConstant.kHttpUrlString] as? String
    XCTAssertEqual(
      actualUrl,
      MockData.testUrl.absoluteString,
      "Incorrect url value! expected = \(MockData.testUrl.absoluteString), \nactual = \(actualUrl)"
    )
  }
  
  
}
