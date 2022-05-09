import UIKit

/**
 Framework constants.
 */
public enum CZHttpFileDownloaderConfig {
  /// Indicates whether to observer `operations` property of OperationQueue. Defaults to false.
  public static var shouldObserveOperations = false
  /// Indicates whether to publish downloading progress to observers. Defaults to false.
  public static var shouldObserveDownloadingProgress = false
  
  /// Indicates whether to enable caching itemsDict. Defaults to false.
  public static var shouldEnableCachedItemsDict = false
  /// Indicates whether to enable local disk cache. Defaults to true.
  public static var enableLocalCache = true
  
  public static var downloadQueueMaxConcurrent = 5
  public static var decodeQueueMaxConcurrent = downloadQueueMaxConcurrent
  public static var errorDomain = "CZHttpFileDownloader"
}
