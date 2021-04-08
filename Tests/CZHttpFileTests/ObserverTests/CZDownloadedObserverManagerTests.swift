import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZDownloadedObserverManagerTests: XCTestCase {
  private enum MockData {
    static let downloadedURLs = [
      URL(string: "http://www.url0.com")!,
      URL(string: "http://www.url1.com")!,
      URL(string: "http://www.url2.com")!,
    ]
  }
  private var downloadedObserverManager: CZDownloadedObserverManager!
  
  override class func setUp() {}
  
  override func setUp() {
    downloadedObserverManager = CZDownloadedObserverManager()
  }
  
  func testAddObserver() {
    let testDownloadedObserver = TestDownloadedObserver()
    
    downloadedObserverManager.addObserver(testDownloadedObserver)
    let isContained = downloadedObserverManager.observers.contains(testDownloadedObserver)
    XCTAssertTrue(isContained, "downloadedObserverManager should have added testDownloadedObserver.")
    
  }
  
  func testPublishDownloadedURLs() {
    let testDownloadedObserver = TestDownloadedObserver()
    
    downloadedObserverManager.addObserver(testDownloadedObserver)
    let isContained = downloadedObserverManager.observers.contains(testDownloadedObserver)
    XCTAssertTrue(isContained, "downloadedObserverManager should have added testDownloadedObserver.")
    
    downloadedObserverManager.publishDownloadedURLs(MockData.downloadedURLs)
    let actualDownloadedURLs = testDownloadedObserver.downloadedURLs
    XCTAssertTrue(
      actualDownloadedURLs == MockData.downloadedURLs,
      "publishDownloadedURLs doesn't work correctly. expected = \(MockData.downloadedURLs), actual = \(actualDownloadedURLs)")
  }
}

private class TestDownloadedObserver: CZDownloadedObserverProtocol {
  fileprivate var downloadedURLs = [URL]()
  
  func downloadedURLsDidUpdate(_ downloadedURLs: [URL]) {
    self.downloadedURLs = downloadedURLs
  }
}
