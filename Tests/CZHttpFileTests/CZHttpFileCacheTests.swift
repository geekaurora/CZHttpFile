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
    // httpFileCache.removeCachedItemsInfo(forUrl: MockData.testUrl)
    Thread.sleep(forTimeInterval: 0.01)
  }
  
  func test1ReadWriteData() {
    // 1. Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)
    
    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)
    
    Thread.sleep(forTimeInterval: 0.01)
    httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
      //XCTAssert(data == readData, "Actual result = \(readData), Expected result = \(data)")
      XCTAssert(readData?.isEqual(to: data) ?? false, "Actual result = \(readData as Data?), Expected result = \(data)")

      // 3. Fulfill the expectatation.
      expectation.fulfill()
    }
    
    // 2. Wait for the expectatation.
    waitForExpectatation()
  }
  
  func test2ReadWriteData() {
    // 1. Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)
    
    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    //httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)
    
    Thread.sleep(forTimeInterval: 0.01)
    httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
      //XCTAssert(data == readData, "Actual result = \(readData), Expected result = \(data)")
      XCTAssert(readData?.isEqual(to: data) ?? false, "Actual result = \(readData as Data?), Expected result = \(data)")

      // 3. Fulfill the expectatation.
      expectation.fulfill()
    }
    
    // 2. Wait for the expectatation.
    waitForExpectatation()
  }
  
  func testReadWriteDataByRelaunchingApp() {
    // Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(5, testCase: self)

    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    // 1. Save cache data.
    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)

    // 2. Read cache data during app running.
    Thread.sleep(forTimeInterval: 0.05)
    httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
      XCTAssert(data == readData as Data?, "Actual result = \(readData), Expected result = \(data)")
    }

    // 3. Relaunching App - read cache data.
    Thread.sleep(forTimeInterval: 0.1)
    //XCUIApplication().launch()
    XCUIApplication().terminate()
    httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
      XCTAssert(data == readData as Data?, "Actual result = \(readData), Expected result = \(data)")

      // Fulfill the expectatation.
      expectation.fulfill()
    }

    // Wait for the expectatation.
    waitForExpectatation()

  }
  
}
