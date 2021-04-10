import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZDownloadingObserverManagerIntegrationTests: XCTestCase {
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
  private var testDownloadingObserver: TestDownloadingObserver!
  
  override class func setUp() {
    let httpFileManager = CZHttpFileManager()
    httpFileManager.cache.clearCache()
    Thread.sleep(forTimeInterval: 0.1)
  }  
  
  override func setUp() {
    httpFileManager = CZHttpFileManager()
    testDownloadingObserver = TestDownloadingObserver()
  }
  
  func testDownloadFileAndPublishDownloadingURLs() {
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)
    
    // 1. Add observer.
    httpFileManager.downloadingObserverManager.addObserver(testDownloadingObserver)
    let isContained = httpFileManager.downloadingObserverManager.observers.contains(testDownloadingObserver)
    XCTAssertTrue(isContained, "downloadingObserverManager should have added testDownloadingObserver.")
    
    // 2. Download file.
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      expectation.fulfill()
    }
    
    // 3. Verify downloadingURLs be published to the observer.
    // Thread.sleep(forTimeInterval: 0.1)
    let actualDownloadingURLs = self.testDownloadingObserver.downloadingURLs
    let expectedDownloadingURLs = [MockData.urlForGet]
    XCTAssertTrue(
      actualDownloadingURLs == expectedDownloadingURLs,
      "publishDownloadingURLs doesn't work correctly. expected = \(expectedDownloadingURLs), \n actual = \(actualDownloadingURLs)")
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
}

private class TestDownloadingObserver: CZDownloadingObserverProtocol {
  fileprivate var downloadingURLs = [URL]()
  
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL]) {
    self.downloadingURLs = downloadingURLs
  }
  
  func downloadingProgressDidUpdate(_ downloadingProgressList: [DownloadingProgress]) {
    
  }
}
