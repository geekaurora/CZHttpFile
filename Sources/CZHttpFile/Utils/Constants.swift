import UIKit

/**
 Framework constants.
 */
public enum CZHttpFileDownloaderConstant {
  /// Indicates whether to observer `operations` property of OperationQueue. Defaults to false.
  public static var shouldObserveOperations = false
  /// Indicates whether to publish downloading progress to observers. Defaults to false.
  public static var shouldObserveDownloadingProgress = false
  public static var downloadQueueMaxConcurrent = 5
  public static var decodeQueueMaxConcurrent = downloadQueueMaxConcurrent
  public static var errorDomain = "CZHttpFileDownloader"
}
