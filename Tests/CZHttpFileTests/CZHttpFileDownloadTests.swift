import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileDownloadTests: XCTestCase {
  private enum MockData {
    static let urlForGet = URL(string: "http://www.test.com/some_file.jpg")!
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
  private let httpFileManager =  CZHttpFileManager.shared
  
  override class func setUp() {
    // Should call clearCache() to clear cached files, otherwise it returns the cached file directly
    // without checking cachedItemDict.
    CZHttpFileTestUtils.clearCacheOfHttpFileManager()
  }
  
  override func setUp() {}
  
  /**
   Test downloaded file.
   */
  func testDownloadFile() {
    // 0-1. Clear cache.
    CZHttpFileTestUtils.clearCacheOfHttpFileManager()

    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    // 0-2. Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)

    // 1. Download file.
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      XCTAssert(!fromCache, "Data shouldn't return from cache.")

      // 2. Verify downloaded data.
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dict, "Actual result = \(res), Expected result = \(MockData.dict)")

      expectation.fulfill()
    }

    // Wait for expectatation.
    waitForExpectatation()
  }
  
  /**
   Test downloaded file from the cache.
   */
  func testDownloadFileFromCache() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)

    /** 1. Download File */
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)

    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      XCTAssert(fromCache, "Data should return from cache.")

      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dict, "Actual result = \(res), Expected result = \(MockData.dict)")

      /** 2. Test Cache */
      Thread.sleep(forTimeInterval: 0.05)
      self.httpFileManager.cache.getCachedFile(withUrl: MockData.urlForGet) { (readData: NSData?) in
        let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: readData as Data?)
        XCTAssert(res == MockData.dict, "Actual result = \(res), Expected result = \(MockData.dict)")

        // Fulfill the expectatation.
        expectation.fulfill()
      }
    }

    // Wait for expectatation.
    waitForExpectatation()
  }
  
  /**
   Test downloaded state.
   */
  func testDownloadState() {
    CZHttpFileTestUtils.clearCacheOfHttpFileManager()
    
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)
    
    self.httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      XCTAssert(!fromCache, "Data shouldn't return from cache.")
      
      // Verify data.
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dict, "Actual result = \(res), Expected result = \(MockData.dict)")
      
      // Verify download state.
      Thread.sleep(forTimeInterval: 0.1)
      let downloadState = self.httpFileManager.downloadState(forURL: MockData.urlForGet)
      XCTAssert(downloadState == .downloaded, "Incorrect downloadState. Actual result = \(downloadState), Expected result = .downloaded")
      
      expectation.fulfill()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  /**
   Test downloaded state from cache.
   */
  func testDownloadStateFromCache() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)

    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)

    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      XCTAssert(fromCache, "Data should return from cache.")

      // Verify data.
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dict, "Actual result = \(res), Expected result = \(MockData.dict)")

      // Verify download state.
      Thread.sleep(forTimeInterval: 0.1)
      let downloadState = self.httpFileManager.downloadState(forURL: MockData.urlForGet)
      XCTAssert(downloadState == .downloaded, "Incorrect downloadState. Actual result = \(downloadState), Expected result = .downloaded")

      expectation.fulfill()
    }

    // Wait for expectatation.
    waitForExpectatation()
  }
  
}

// MARK: - Private methods

private extension CZHttpFileDownloadTests {}
