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
  private var downloader: CZHttpFileDownloader<NSData>
  public internal(set) var cache: CZHttpFileCache

  public enum Config {
    public static var maxConcurrencies = 5
  }
  
  public override init() {
    cache = CZHttpFileCache()
    downloader = CZHttpFileDownloader(cache: cache)
    super.init()
  }
  
  public func downloadFile(url: URL,
                           priority: Operation.QueuePriority = .normal,
                           progress: HTTPRequestWorker.Progress? = nil,
                           completion: @escaping CZHttpFileDownloderCompletion) {
    cache.getCachedFile(withUrl: url) { [weak self] (data: NSData?) in
      guard let `self` = self else { return }
      //      if let data = data as Data? {
      //        // Load from local disk.
      //        MainQueueScheduler.sync {
      //          completion(data, nil, true)
      //        }
      //        return
      //      }
      
      // Load from http service.
      self.downloader.downloadHttpFile(
        url: url,
        priority: priority,
        progress: progress,
        completion: { (data: NSData?, error: Error?, fromCache: Bool) in
          completion(data as Data?, error, fromCache)
        })
    }
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL) {
    downloader.cancelDownload(with: url)
  }
  
  /**
   Returns cached file URL if has been downloaded, otherwise nil.
   */
  public func cachedFileURL(forURL httpURL: URL?) -> URL? {
    let (fileURL, isExisting) = cache.cachedFileURL(forURL: httpURL)
    return isExisting ? fileURL: nil
  }
}
