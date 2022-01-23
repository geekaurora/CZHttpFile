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
  let httpFileCache = CZHttpFileManager.shared.cache
  
  override class func setUp() {
    CZHttpFileTestUtils.clearCacheOfHttpFileManager()
  }
  
  // MARK: - setCacheFile
  
  /**
   Test of setCacheFile(withUrl:data:completeSetCachedItemsDict:completeSaveCachedFile:)
   */
  func testSetCacheFile() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    // 0. Clear cache of HttpFileManager.
    clearCacheOfHttpFileManager()
    
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    let (_, cacheKey) = httpFileCache.getCacheFileInfo(forURL: MockData.testUrl)
    // 1. Set file to cache.
    httpFileCache.setCacheFile(
      withUrl: MockData.testUrl,
      data: mockData) {
      // 2-1. Verify: saved cachedItemDict.
      let cachedItemsDict = self.httpFileCache.diskCacheManager.getCachedItemsDict()
      let actualUrl = cachedItemsDict[cacheKey]?[CacheConstant.kHttpUrlString] as? String
      XCTAssertTrue(actualUrl == MockData.testUrl.absoluteString, "cachedItemsDict isn't correct! expectedUrl = \(MockData.testUrl), actualUrl = \(actualUrl)")
    } completeSaveCachedFile: {
      // 2-2. Verify: saved file.
      let (fileUrl, _) = self.httpFileCache.cachedFileURL(forURL: MockData.testUrl)
      let isFileExisting = CZFileHelper.fileExists(url:fileUrl)
      XCTAssertTrue(isFileExisting, "File should have been saved. fileUrl = \(fileUrl)")
      
      // 3. Fulfill.
      expectation.fulfill()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  // MARK: - CachedItemsDict

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
  
  // TODO: fix test.
//  func testSetCachedItemsDict2_ReadFromCache() {
//    // Verify from cache: getCachedItemsDict.
//    let cachedItemsDict = httpFileCache.diskCacheManager.getCachedItemsDict()
//    let actualValue = cachedItemsDict[MockData.key]?[CacheConstant.kFileSize] as? Int
//    XCTAssertEqual(
//      actualValue,
//      MockData.testSize,
//      "Incorrect value! expected = \(MockData.testSize), \nactual = \(actualValue)"
//    )
//  }
  
  // MARK: - Clear Cache

  // TODO: fix test.
//  func testClearCache() {
//    // 1. Write file to cache and cachedItemsDict.
//    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
//    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data, completeSetCachedItemsDict: nil)
//    Thread.sleep(forTimeInterval: 0.05)
//    
//    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
//
//    // 2. Call clearCache().
//    let (fileUrl, _) = httpFileCache.cachedFileURL(forURL: MockData.testUrl)
//    httpFileCache.clearCache {
//      // 3-1. Verify: Info in cachedItemDict is removed.
//      let cachedItemsDict = self.httpFileCache.diskCacheManager.getCachedItemsDict()
//      let (_, cacheKey) = self.httpFileCache.diskCacheManager.getCacheFileInfo(forURL: MockData.testUrl)
//      let isCachedItemsDictKeyExisting = (cachedItemsDict[cacheKey] != nil)
//      XCTAssertTrue(!isCachedItemsDictKeyExisting, "CachedItemsDict key should have been removed. url = \(MockData.testUrl)")
//
//      // 3-2. Verify: memCache is removed.
//      let isExistingInMemCache = (self.httpFileCache.getMemCache(forKey: cacheKey) != nil)
//      XCTAssertTrue(!isExistingInMemCache, "File should have been removed. fileUrl = \(fileUrl)")
//      
//      // 3-3. Verify: cached file is removed.
//      let isExistingInDiskCache = CZFileHelper.fileExists(url:fileUrl)
//      XCTAssertTrue(!isExistingInDiskCache, "File should have been removed. fileUrl = \(fileUrl)")
//
//      expectation.fulfill()
//    }
//    
//    // Wait for expectatation.
//    waitForExpectatation()
//  }
    
}

private extension CZDiskCacheManagerTests {
  func clearCacheOfHttpFileManager() {
    httpFileCache.clearCache()
    Thread.sleep(forTimeInterval: 0.1)
  }
}
