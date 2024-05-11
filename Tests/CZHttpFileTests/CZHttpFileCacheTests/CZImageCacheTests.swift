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
    guard let systemImage = UIImage(systemName: "heart.fill").assertIfNil,
          let image = systemImage.pngImage.assertIfNil else {
      return
    }
    // After converting to PNG, the transferred data are the same. (Second time works, first time not)
    let imageData = image.pngData()!
    
    // 1. Call `imageCache.transformDataToModel` to transform Data to Image.
    let transformedImage = imageCache.transformDataToModel(imageData)
    
    // 2. Verify the transferred image is correct.
    let transformedImageData = transformedImage!.pngData()!
    XCTAssert(imageData == transformedImageData)
  }
}

/**
`CZImageDiffHelper.compare` doesn't work - memory compare.
 
 do {
   //let isEqual = try CZImageDiffHelper.compare(expected: imageData, observed: transformedImageData)
   let isEqual = try CZImageDiffHelper.compare(expected: imageData, actual: imageData)
   XCTAssert(isEqual)
 } catch {
  assertionFailure("Failed to compare images. error \(error.localizedDescription)")
 }
 */
