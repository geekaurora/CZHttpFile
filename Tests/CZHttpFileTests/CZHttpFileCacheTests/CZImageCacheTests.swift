import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

final class CZImageCacheTests: XCTestCase {
  var imageCache: CZImageCache!
  
  override func setUp() {
    imageCache = CZImageCache()
  }
  
  func testDataTransformerToImage() {
    guard #available(iOS 13.0, *) else {
      assertionFailure("Should run tests above iOS 13.0.")
      return
    }
    guard let image = UIImage(systemName: "heart.fill").assertIfNil else {
      return
    }
    let imageData = image.pngData()!
    let transformedImage = imageCache.transformMetadataToCachedData(imageData)
    let transformedImageData = transformedImage!.pngData()!
    
    do {
      let isEqual = try CZImageDiffHelper.compare(expected: imageData, observed: transformedImageData)
      // XCTAssert(isEqual)
    } catch {
      assertionFailure("Failed to compare images. error \(error.localizedDescription)")
    }
  }
  
  
}
