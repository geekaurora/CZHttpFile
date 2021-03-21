import UIKit
import CZUtils
import CZNetworking

public typealias CZHttpFileDownloderCompletion = (_ data: Data?, _ error: Error?, _ fromCache: Bool) -> Void

/**
 Web file manager maintains asynchronous web file downloading tasks.
 
 - Note: the default Data type is `Data`.
 */
@objc open class CZHttpFileManager: NSObject {

    public static let shared: CZHttpFileManager = CZHttpFileManager()
    private var downloader: CZHttpFileDownloader<NSData>
    internal var cache: CZHttpFileCache
    
    public override init() {
      cache = CZHttpFileCache()
      downloader = CZHttpFileDownloader(cache: cache)
        super.init()
    }
    
    public func downloadFile(with url: URL,
                       priority: Operation.QueuePriority = .normal,
                       completion: @escaping CZHttpFileDownloderCompletion) {
      cache.getCachedFile(with: url) { [weak self] (data) in
            guard let `self` = self else { return }
            if let data = data as? Data {
                // Load from local disk
                MainQueueScheduler.sync {
                    completion(data, nil, true)
                }
                return
            }
        
            // Load from http service
//        self.downloader.downloadHttpFile(
//          with: url,
//          priority: priority,
//          completion: completion)
        
//            self.downloader.downloadImage(with: url,
//                                          priority: priority,
//                                          completion: completion)
        }
    }
    
    @objc(cancelDownloadWithURL:)
    public func cancelDownload(with url: URL) {
        downloader.cancelDownload(with: url)
    }
}
