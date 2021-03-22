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
    static let array: [AnyHashable] = [
      "sdlfjas",
      "sdlksdf",
      "239823sd",
      189298723,
    ]
  }
  var httpFileCache: CZHttpFileCache!
  
  override func setUp() {
    httpFileCache = CZHttpFileCache()
    httpFileCache.removeCachedItemsInfo(forUrl: MockData.testUrl)
    Thread.sleep(forTimeInterval: 0.01)
  }
  
  func testReadWriteData() {
    // 1. Intialize the async expectation.
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(1, testCase: self)

    let data = CZHTTPJsonSerializer.jsonData(with: MockData.dict)!
    httpFileCache.setCacheFile(withUrl: MockData.testUrl, data: data)
    
    Thread.sleep(forTimeInterval: 0.1)
    DispatchQueue.global().async {
      self.httpFileCache.getCachedFile(with: MockData.testUrl) { (readData: NSData?) in
        XCTAssert(data == readData as Data?, "Actual result = \(readData), Expected result = \(data)")
        // 3. Fulfill the expectatation.
        expectation.fulfill()
      }
    }

    // 2. Wait for the expectatation.
    waitForExpectatation()
  }
  
//
//  func testReadWriteDictionary() {
//    let dictionary = MockData.dict
//    httpFileCache.saveData(dictionary, forKey: MockData.key)
//    Thread.sleep(forTimeInterval: 0.01)
//
//    let readDictionary = httpFileCache.readData(forKey: MockData.key) as? [String: AnyHashable]
//    XCTAssert(dictionary == readDictionary, "Actual result = \(readDictionary), Expected result = \(dictionary)")
//  }
//
//  func testReadWriteArray() {
//    let array = MockData.array
//    httpFileCache.saveData(array, forKey: MockData.key)
//    Thread.sleep(forTimeInterval: 0.01)
//
//    let readArray = httpFileCache.readData(forKey: MockData.key) as? [AnyHashable]
//    XCTAssert(array == readArray, "Actual result = \(readArray), Expected result = \(array)")
//  }
}
