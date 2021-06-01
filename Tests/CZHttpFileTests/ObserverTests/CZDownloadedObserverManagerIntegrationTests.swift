import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZDownloadedObserverManagerIntegrationTests: XCTestCase {
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
  private var testDownloadedObserver: TestDownloadedObserver!
  
  override class func setUp() {
    let httpFileManager = CZHttpFileManager()
    httpFileManager.cache.clearCache()
    Thread.sleep(forTimeInterval: 0.1)
  }
  
  override func setUp() {
    CZHttpFileManager.Config.shouldEnableDownloadObservers = true
    httpFileManager = CZHttpFileManager()
    testDownloadedObserver = TestDownloadedObserver()
  }
  
  func testDownloadFileAndPublishDownloadedURLs() {    
    let (waitForExpectatation, expectation) = CZTestUtils.waitWithInterval(Constant.timeOut, testCase: self)
    
    // Create mockDataMap.
    let mockData = CZHTTPJsonSerializer.jsonData(with: MockData.dictionary)!
    let mockDataDict = [MockData.urlForGet: mockData]
    CZHTTPManager.stubMockData(dict: mockDataDict)
    
    // 1. Add observer.
    httpFileManager.downloadedObserverManager!.addObserver(testDownloadedObserver)
    let isContained = httpFileManager.downloadedObserverManager?.observers.contains(testDownloadedObserver) ?? false
    XCTAssertTrue(isContained, "downloadedObserverManager should have added testDownloadedObserver.")
    
    // 2. Download file.
    httpFileManager.downloadFile(url: MockData.urlForGet) { (data: Data?, error: Error?, fromCache: Bool) in
      
      // 3. Verify downloadedURLs be published to the observer.
      Thread.sleep(forTimeInterval: 0.1)
      let actualDownloadedURLs = self.testDownloadedObserver.downloadedURLs
      let expectedDownloadedURLs = [MockData.urlForGet]
      XCTAssertTrue(
        actualDownloadedURLs == expectedDownloadedURLs,
        "publishDownloadedURLs doesn't work correctly. expected = \(expectedDownloadedURLs), \n actual = \(actualDownloadedURLs)")
      
      expectation.fulfill()
    }
    
    // Wait for expectatation.
    waitForExpectatation()
  }
  
}

private class TestDownloadedObserver: CZDownloadedObserverProtocol {
  fileprivate var downloadedURLs = [URL]()
  
  func downloadedURLsDidUpdate(_ downloadedURLs: [URL]) {
    self.downloadedURLs = downloadedURLs
  }
}
