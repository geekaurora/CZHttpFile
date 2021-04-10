import UIKit
import CZUtils
import CZNetworking

public typealias CZHttpFileDownloderCompletion = (_ data: Data?, _ error: Error?, _ fromCache: Bool) -> Void

/**
 Web file manager maintains asynchronous web file downloading tasks.
 
 - Note: the default Data type is `Data`.
 */
@objc open class CZHttpFileManager: NSObject {

  public static let shared: CZHttpFileManager = {
    CZHTTPManager.Config.maxConcurrencies = Config.maxConcurrencies
    let shared = CZHttpFileManager()
    return shared
  }()
  public let downloader: CZHttpFileDownloader<NSData>
  public let cache: CZHttpFileCache
  
  public let downloadingObserverManager: CZDownloadingObserverManager
  public let downloadedObserverManager: CZDownloadedObserverManager
  
  public enum Config {
    public static var maxConcurrencies = 5
  }
  
  public override init() {
    downloadingObserverManager = CZDownloadingObserverManager()
    downloadedObserverManager = CZDownloadedObserverManager()
    cache = CZHttpFileCache(downloadedObserverManager: downloadedObserverManager)
    downloader = CZHttpFileDownloader(cache: cache, downloadingObserverManager: downloadingObserverManager)
    super.init()    
  }
  
  // MARK: - Download
  
  public func downloadFile(url: URL,
                           priority: Operation.QueuePriority = .normal,
                           progress: HTTPRequestWorker.Progress? = nil,
                           completion: @escaping CZHttpFileDownloderCompletion) {
    cache.getCachedFile(withUrl: url) { [weak self] (data: NSData?) in
      guard let `self` = self else { return }
      if let data = data as Data? {
        // Load from local disk.
        MainQueueScheduler.sync {
          completion(data, nil, true)
        }
        return
      }
      
      // Load from http service.
      self.downloader.downloadHttpFile(
        url: url,
        priority: priority,
        progress: { [weak self] (currSize, totalSize, downloadURL) in
          progress?(currSize, totalSize, downloadURL)
          self?.publishDownloadProgressIfNeeded(currSize, totalSize, downloadURL)
        },
        completion: { (data: NSData?, error: Error?, fromCache: Bool) in
          completion(data as Data?, error, fromCache)
        })
    }
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL) {
    downloader.cancelDownload(with: url)
  }
}

// MARK: - Helper methods

public extension CZHttpFileManager {
  /**
   Returns cached file URL if has been downloaded, otherwise nil.
   */
  func cachedFileURL(forURL httpURL: URL?) -> URL? {
    let (fileURL, isExisting) = cache.cachedFileURL(forURL: httpURL)
    return isExisting ? fileURL: nil
  }
  
  /**
   Returns the download state of `url`.
   */
  func downloadState(forURL httpURL: URL?) -> CZHttpFileDownloadState {
    if let _ = cachedFileURL(forURL:httpURL) {
      return .downloaded
    }
    if downloader.downloadingURLs.contains(where: { $0 == httpURL }) {
      return .downloading
    }
    return .none
  }
}

// MARK: - Private methods

private extension CZHttpFileManager {
  func publishDownloadProgressIfNeeded(_ currSize: Int64, _ totalSize: Int64, _ downloadURL: URL) {
    guard CZHttpFileDownloaderConfig.shouldObserveDownloadingProgress else {
      return
    }
    let progress = Double(currSize) / Double(totalSize)
    downloadingObserverManager.publishDownloadingProgress(url: downloadURL, progress: progress)
  }
}
