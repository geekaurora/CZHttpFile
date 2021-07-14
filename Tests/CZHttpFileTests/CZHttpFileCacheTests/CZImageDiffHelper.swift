import XCTest
import CZUtils
import CZTestUtils
import CZNetworking
@testable import CZHttpFile

/**
 Helper that compares two images with `tolerance`.
 
 https://github.com/facebookarchive/ios-snapshot-test-case/blob/master/FBSnapshotTestCase/Categories/UIImage%2BCompare.m
 */
class CZImageDiffHelper {
  
  static func compare(expected: Data,
                      observed: Data,
                      tolerance: Float = 0.1) throws -> Bool {
    guard let expectedUIImage = UIImage(data: expected), let observedUIImage = UIImage(data: observed) else {
      throw CZError(domain: "unableToGetUIImageFromData")
    }
    guard let expectedCGImage = expectedUIImage.cgImage, let observedCGImage = observedUIImage.cgImage else {
      throw CZError(domain: "unableToGetUIImageFromData")
    }
    guard let expectedColorSpace = expectedCGImage.colorSpace, let observedColorSpace = observedCGImage.colorSpace else {
      throw CZError(domain: "unableToGetUIImageFromData")
    }
    
    // 1. Compare width / height.
    if expectedCGImage.width != observedCGImage.width || expectedCGImage.height != observedCGImage.height {
      throw CZError(domain: "unableToGetUIImageFromData")
    }
    let imageSize = CGSize(width: expectedCGImage.width, height: expectedCGImage.height)
    let numberOfPixels = Int(imageSize.width * imageSize.height)
    
    // Checking that our `UInt32` buffer has same number of bytes as image has.
    let bytesPerRow = min(expectedCGImage.bytesPerRow, observedCGImage.bytesPerRow)
        
    let val1 = MemoryLayout<UInt32>.stride              // 4
    let val2 = bytesPerRow / Int(imageSize.width)       // 2
    // assert(val1 == val2)
    
    let expectedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)
    let observedPixels = UnsafeMutablePointer<UInt32>.allocate(capacity: numberOfPixels)
    
    let expectedPixelsRaw = UnsafeMutableRawPointer(expectedPixels)
    let observedPixelsRaw = UnsafeMutableRawPointer(observedPixels)
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    // 2-0. Create CGContext for rendering.
    guard let expectedContext = CGContext(
            data: expectedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
            bitsPerComponent: expectedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
            space: expectedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
      expectedPixels.deallocate()
      observedPixels.deallocate()
      throw CZError(domain: "unableToGetUIImageFromData")
    }
    guard let observedContext = CGContext(
            data: observedPixelsRaw, width: Int(imageSize.width), height: Int(imageSize.height),
            bitsPerComponent: observedCGImage.bitsPerComponent, bytesPerRow: bytesPerRow,
            space: observedColorSpace, bitmapInfo: bitmapInfo.rawValue) else {
      expectedPixels.deallocate()
      observedPixels.deallocate()
      throw CZError(domain: "unableToGetUIImageFromData")
    }
    
    // 2-1. Draw image with CGContext.
    expectedContext.draw(expectedCGImage, in: CGRect(origin: .zero, size: imageSize))
    observedContext.draw(observedCGImage, in: CGRect(origin: .zero, size: imageSize))
    
    let expectedBuffer = UnsafeBufferPointer(start: expectedPixels, count: numberOfPixels)
    let observedBuffer = UnsafeBufferPointer(start: observedPixels, count: numberOfPixels)
    
    // 2-2. Compare pixels of two images with `tolerance`.
    var isEqual = true
    if tolerance == 0 {
      isEqual = expectedBuffer.elementsEqual(observedBuffer)
    } else {
      // Go through each pixel in turn and see if it is different
      var numDiffPixels = 0
      for pixel in 0 ..< numberOfPixels where expectedBuffer[pixel] != observedBuffer[pixel] {
        // If this pixel is different, increment the pixel diff count and see if we have hit our limit.
        numDiffPixels += 1
        let percentage = 100 * Float(numDiffPixels) / Float(numberOfPixels)
        if percentage > tolerance {
          isEqual = false
          break
        }
      }
    }
    
    expectedPixels.deallocate()
    observedPixels.deallocate()
    
    return isEqual
  }
}
