import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileDownloadTests: XCTestCase {
  private enum MockData {
    static let urlForGet = URL(string: "http://www.test.com/some_file.jpg")!
    static let dictionary: [String: AnyHashable] = [
      "a": "sdlfjas",
      "c": "sdlksdf",
      "b": "239823sd",
      "d": 189298723,
    ]
  }
  private enum Constant {
    static let timeOut: TimeInterval = 30
  }
  private var httpFileManager: CZHttpFileManager!
  
  override class func setUp() {
    let httpFileManager = CZHttpFileManager()    
    // Should call clearCache() to clear cached files, otherwise it returns the cached file directly
    // without checking cachedItemDict.
    httpFileManager.cache.clearCache()
    // httpFileManager.cache.diskCacheManager.removeCachedItemsDict(forUrl: MockData.urlForGet)
    
    Thread.sleep(forTimeInterval: 0.1)
  }
  
  override func setUp() {
    httpFileManager = CZHttpFileManager()
  }
  
  /**
   Test downloaded file.
   */
  func testDownloadFile() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)
    
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
      expectation.fulfill()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  /**
   Test downloaded file and verify cached data.
   */
  func testDownloadFileWithCache() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    /** 1. Download File */
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)
    
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
            
      /** 2. Test Cache */
      Thread.sleep(forTimeInterval: 0.05)
      self.httpFileManager.cache.getCachedFile(withUrl: MockData.urlForGet) { (readData: NSData?) in
        let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: readData as Data?)
        XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")

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
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)
    
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      // Verify data.
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
      
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
