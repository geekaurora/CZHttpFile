import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileCacheTests: XCTestCase {
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
  
  func testReadWriteData1() {
    // 1. Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)
    
    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data, completeSetCachedItemsDict: nil)
    
    Thread.sleep(forTimeInterval: 0.05)
    
    // Verify file exists with `cachedFileURL(:)`.
    let (fileURL, isExisting) = httpFileCache.cachedFileURL(forURL: MockData.testUrl)
    XCTAssert(fileURL != nil, "File should have been saved on disk and cacheItemsDict. url = \(MockData.testUrl), fileURL = \(fileURL)")
    XCTAssert(isExisting, "File should have been saved on disk and cacheItemsDict. url = \(MockData.testUrl)")

    httpFileCache.getCachedFile(withUrl: MockData.testUrl) { (readData: NSData?) in
      let readData = readData as Data?
      XCTAssert(data == readData, "Actual result = \(readData), Expected result = \(data)")

      // 3. Fulfill the expectatation.
      expectation.fulfill()
    }
    
    // 2. Wait for the expectatation.
    waitForExpectatation()
  }
  
  /// Test read from cache after relaunching App / ColdStart (written by the precious test).
  /// It verifies both DiskCache and MemCache.
  ///
  /// - Note: Should run `testReadWriteData1` first!
  ///
  /// As Swift doesn't support `testInvocations` override, so can only order tests by alphabet names
  /// to simulate relaunching App.
  func testReadWriteData2AfterRelaunchingApp() {
    // 1. Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)
    
    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    //httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)
    let (_, cacheKey) = self.httpFileCache.getCacheFileInfo(forURL: MockData.testUrl)
    
    Thread.sleep(forTimeInterval: 0.01)
    httpFileCache.getCachedFile(withUrl: MockData.testUrl) { (readData: NSData?) in
      let readData = readData as Data?
      XCTAssert(data == readData, "Actual result = \(readData), Expected result = \(data)")

      // Verify MemCache.
      let dataFromMemCache = self.httpFileCache.getMemCache(forKey: cacheKey) as Data?
      XCTAssert(dataFromMemCache == readData, "MemCache failed! Actual result = \(readData), Expected result = \(data)")

      // 3. Fulfill the expectatation.
      expectation.fulfill()
    }
    
    // 2. Wait for the expectatation.
    waitForExpectatation()
  }
  
}
