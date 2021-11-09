import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZHttpFileManagerTests: XCTestCase {

  // MARK: - Config
  
  func testConfigMaxSize() {
    let expectedMaxCacheSize = -1
    CZHttpFileManager.Config.kMaxCacheSize = expectedMaxCacheSize
    XCTAssertTrue(
      CZHttpFileManager.shared.cache.maxCacheSize == expectedMaxCacheSize,
      "ConfigMaxAge doesn't match. expected = \(expectedMaxCacheSize), actual = \(CZHttpFileManager.shared.cache.maxCacheSize)"
    )
  }
  
  func testConfigMaxAge() {
    let expectedMaxCacheAge: TimeInterval = -1
    CZHttpFileManager.Config.kMaxCacheAge = expectedMaxCacheAge
    XCTAssertTrue(
      CZHttpFileManager.shared.cache.maxCacheAge == expectedMaxCacheAge,
      "ConfigMaxAge doesn't match. expected = \(expectedMaxCacheAge), actual = \(CZHttpFileManager.shared.cache.maxCacheAge)"
    )
  }
  
}
