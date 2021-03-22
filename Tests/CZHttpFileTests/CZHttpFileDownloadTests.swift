import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileDownloadTests: XCTestCase {
  private enum MockData {
    static let urlForGet = URL(string: "https://www.apple.com/newsroom/rss-feed-GET.rss")!
    static let urlForGetCodable = URL(string: "https://www.apple.com/newsroom/rss-feed-GETCodable.rss")!
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
    static let models = (0..<10).map { TestModel(id: $0, name: "Model\($0)") }
  }
  static let queueLable = "com.tests.queue"
  @ThreadSafe
  private var executionSuccessCount = 0
  
  override func setUp() {
    executionSuccessCount = 0
  }
  
  func testGET() {
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

struct TestModel: Codable {
  let id: Int
  let name: String
}
