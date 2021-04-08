import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
import CZHttpFile

/// Helper methods for CZHttpFile tests.
class CZHttpFileTestUtils {
  /**
   Clear cache of HttpFileManager.
   
   - Note: Shouldn't call clearCache() in tearDown which only removes cachedItemDict but not cached files,
   it makes cached files untracked by clearCache().
   */
  static func clearCacheOfHttpFileManager() {
    CZHttpFileManager.shared.cache.clearCache()
    Thread.sleep(forTimeInterval: 0.1)
  }  
}
