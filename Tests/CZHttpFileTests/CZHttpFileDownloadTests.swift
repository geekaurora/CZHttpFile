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
  private var httpFileManager: CZHttpFileManager!
  
  override func setUp() {
    httpFileManager = CZHttpFileManager()
  }
  
  func testDownloadFile() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(30, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataMap = [MockData.urlForGet: mockData]
    
    // Fetch with stub URLSession.
    let sessionConfiguration = CZHTTPStub.stubURLSessionConfiguration(mockDataMap: mockDataMap)
    // Replace urlSessionConfiguration of CZHTTPManager to stub data.
    CZHTTPManager.urlSessionConfiguration = sessionConfiguration
    
    
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
      expectation.fulfill()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  func testCZHTTPManagerGET() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(30, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataMap = [MockData.urlForGet: mockData]
    
    // Fetch with stub URLSession.
    let sessionConfiguration = CZHTTPStub.stubURLSessionConfiguration(mockDataMap: mockDataMap)
    // Replace urlSessionConfiguration of CZHTTPManager to stub data.
    CZHTTPManager.urlSessionConfiguration = sessionConfiguration
    CZHTTPManager.shared.GET(MockData.urlForGet.absoluteString, success: { (_, data) in
      let res: [String: AnyHashable]? = CZHTTPJsonSerializer.deserializedObject(with: data)
      XCTAssert(res == MockData.dictionary, "Actual result = \(res), Expected result = \(MockData.dictionary)")
      expectation.fulfill()
    })
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
  //  func testReadWriteData1() {
  //    // 1. Intialize the async expectation.
  //    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)
  //
  //    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
  //    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)
  //
  //    Thread.sleep(forTimeInterval: 0.01)
  //    httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
  //      let readData = readData as Data?
  //      XCTAssert(data == readData, "Actual result = \(readData), Expected result = \(data)")
  //
  //      // 3. Fulfill the expectatation.
  //      expectation.fulfill()
  //    }
  //
  //    // 2. Wait for the expectatation.
  //    waitForExpectatation()
  //  }
  
}

// MARK: - Helper methods

private extension CZHttpFileDownloadTests {
  
}

struct TestModel: Codable {
  let id: Int
  let name: String
}
