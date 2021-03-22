import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileDownloadTests: XCTestCase {
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
    // httpFileCache.removeCachedItemsInfo(forUrl: MockData.testUrl)
    Thread.sleep(forTimeInterval: 0.01)
  }
  
  func testReadWriteData1() {
    // 1. Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)
    
    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)
    
    Thread.sleep(forTimeInterval: 0.01)
    httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
      let readData = readData as Data?
      XCTAssert(data == readData, "Actual result = \(readData), Expected result = \(data)")

      // 3. Fulfill the expectatation.
      expectation.fulfill()
    }
    
    // 2. Wait for the expectatation.
    waitForExpectatation()
  }
  
  
}
