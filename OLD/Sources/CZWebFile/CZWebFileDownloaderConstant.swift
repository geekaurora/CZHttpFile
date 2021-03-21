import UIKit

/**
 Framework constants.
 */
public enum CZWebFileDownloaderConstant {
  public static var shouldObserveOperations = false
  public static var downloadQueueMaxConcurrent = 5
  public static var decodeQueueMaxConcurrent = downloadQueueMaxConcurrent
  public static var errorDomain = "CZWebFileDownloader"
}
