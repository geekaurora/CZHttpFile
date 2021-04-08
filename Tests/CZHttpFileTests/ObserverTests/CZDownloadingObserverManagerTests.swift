import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZDownloadingObserverManagerTests: XCTestCase {
  private enum MockData {
    static let downloadingURLs = [
      URL(string: "http://www.url0.com")!,
      URL(string: "http://www.url1.com")!,
      URL(string: "http://www.url2.com")!,
    ]
  }
  private var downloadingObserverManager: CZDownloadingObserverManager!
  
  override class func setUp() {}
  
  override func setUp() {
    downloadingObserverManager = CZDownloadingObserverManager()
  }
  
  func testAddObserver() {
    let testDownloadingObserver = TestDownloadingObserver()
    downloadingObserverManager.addObserver(testDownloadingObserver)
    let isContained = downloadingObserverManager.observers.contains(testDownloadingObserver)
    XCTAssertTrue(isContained, "downloadingObserverManager should have added testDownloadingObserver.")
  }
  
  func testPublishDownloadingURLs() {
    let testDownloadingObserver = TestDownloadingObserver()
    
    downloadingObserverManager.addObserver(testDownloadingObserver)
    let isContained = downloadingObserverManager.observers.contains(testDownloadingObserver)
    XCTAssertTrue(isContained, "downloadingObserverManager should have added testDownloadingObserver.")
    
    downloadingObserverManager.publishDownloadingURLs(MockData.downloadingURLs)
    let actualDownloadingURLs = testDownloadingObserver.downloadingURLs
    XCTAssertTrue(
      actualDownloadingURLs == MockData.downloadingURLs,
      "publishDownloadingURLs doesn't work correctly. expected = \(MockData.downloadingURLs), actual = \(actualDownloadingURLs)")
  }
}

private class TestDownloadingObserver: CZDownloadingObserverProtocol {
  fileprivate var downloadingURLs = [URL]()
  
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL]) {
    self.downloadingURLs = downloadingURLs
  }
}
