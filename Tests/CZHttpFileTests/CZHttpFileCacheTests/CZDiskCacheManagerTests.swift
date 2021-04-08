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
  private enum Constant {
    static let timeOut: TimeInterval = 30
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
  
  func testClearCache() {
    // 1. Write file to cache and cachedItemsDict.
    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data, completeSetCachedItemsDict: nil)
    Thread.sleep(forTimeInterval: 0.05)
    
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)

    // 2. Call clearCache().
    let (fileUrl, _) = httpFileCache.cachedFileURL(forURL: MockData.testUrl)
    httpFileCache.clearCache {
      // 3-1. Verify: Info in cachedItemDict is removed.
      let cachedItemsDict = self.httpFileCache.diskCacheManager.getCachedItemsDict()
      let (_, cacheKey) = self.httpFileCache.diskCacheManager.getCacheFileInfo(forURL: MockData.testUrl)
      let isCachedItemsDictKeyExisting = (cachedItemsDict[cacheKey] != nil)
      XCTAssertTrue(!isCachedItemsDictKeyExisting, "CachedItemsDict key should have been removed. url = \(MockData.testUrl)")

      // 3-2. Verify: file is removed.
      let isFileExisting = CZFileHelper.fileExists(url:fileUrl)
      XCTAssertTrue(!isFileExisting, "File should have been removed. fileUrl = \(fileUrl)")

      expectation.fulfill()
    }  
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
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
