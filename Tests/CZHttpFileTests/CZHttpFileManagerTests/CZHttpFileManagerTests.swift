import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileManagerTests: XCTestCase {
  public typealias GetRequestSuccess = (Data?) -> Void
  
  private enum Constant {
    static let timeOut: TimeInterval = 10
  }
  private enum MockData {
    static let urlForGet = URL(string: "https://www.apple.com/newsroom/rss-feed-GET.rss")!
    static let urlForGetCodable = URL(string: "https://www.apple.com/newsroom/rss-feed-GETCodable.rss")!
    static let urlForGetDictionaryable = URL(string: "https://www.apple.com/newsroom/rss-feed-GetDictionaryable.rss")!
    static let urlForGetDictionaryableOneModel = URL(string: "https://www.apple.com/newsroom/rss-feed-GetDictionaryableOneModel.rss")!
    
    static let dictionary: [String: AnyHashable] = [
      "a": "sdlfjas",
      "c": "sdlksdf",
      "b": "239823sd",
      "d": 189298723,
    ]
    static let array: [AnyHashable] = [
      "sdlfjas",
      "sdlksdf",
      "239823sd",
      189298723,
    ]
  }
  
  static let queueLable = "com.tests.queue"
  @ThreadSafe
  private var executionSuccessCount = 0
  private var czHttpFileManager: CZHttpFileManager!
  
  override func setUp() {
    executionSuccessCount = 0

    czHttpFileManager = CZHttpFileManager()
    czHttpFileManager.cache.clearCache()
  }
  
  // MARK: - Download
  
  /**
   Test downloadFile() method.
   */
  func testDownloadFile() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataMap = [MockData.urlForGet: mockData]
    
    // Stub MockData.
    CZHTTPManager.stubMockData(dict: mockDataMap)
    
    czHttpFileManager.downloadFile(url: MockData.urlForGet) { data, error, fromCache in
      XCTAssert(!fromCache, "Result should return from network - not from cache. fromCache = \(fromCache)")

      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
      expectation.fulfill()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  
  /**
   Test downloadFile() method - verify result from mem cache.
   */
  func testDownloadFileFromCache1() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataMap = [MockData.urlForGet: mockData]
    
    // 0. Stub MockData.
    CZHTTPManager.stubMockData(dict: mockDataMap)
    
    // 1. Fetch with stub URLSession.
    czHttpFileManager.downloadFile(url: MockData.urlForGet) { data, error, fromCache in
      XCTAssert(!fromCache, "Result should return from network - not from cache. fromCache = \(fromCache)")

      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
    }
    
    // 2. Verify cache: fetch again.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.czHttpFileManager.downloadFile(url: MockData.urlForGet) { data, error, fromCache in
        XCTAssert(fromCache, "Result should return from mem cache. fromCache = \(fromCache)")

        let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
        XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
        expectation.fulfill()
      }
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  // MARK: - Config
  
  func testConfigMaxSize() {
    let expectedMaxCacheSize = -1
    CZHttpFileManager.Config.kMaxCacheSize = expectedMaxCacheSize
    XCTAssertTrue(
      CZHttpFileManager.shared.cache.maxCacheSize == expectedMaxCacheSize,
      "ConfigMaxAge doesn't match. expected = \(expectedMaxCacheSize), actual = \(CZHttpFileManager.shared.cache.maxCacheSize)"
    )
  }
  
  func testConfigMaxAge() {
    let expectedMaxCacheAge: TimeInterval = -1
    CZHttpFileManager.Config.kMaxCacheAge = expectedMaxCacheAge
    XCTAssertTrue(
      CZHttpFileManager.shared.cache.maxCacheAge == expectedMaxCacheAge,
      "ConfigMaxAge doesn't match. expected = \(expectedMaxCacheAge), actual = \(CZHttpFileManager.shared.cache.maxCacheAge)"
    )
  }
  
}
