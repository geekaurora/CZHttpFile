import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
import CZHttpFile

/// Helper methods for CZHttpFile tests.
class CZHttpFileTestUtils {
  static func clearCacheOfHttpFileManager() {
    CZHttpFileManager.shared.cache.clearCache()
    Thread.sleep(forTimeInterval: 1)
  }  
}
