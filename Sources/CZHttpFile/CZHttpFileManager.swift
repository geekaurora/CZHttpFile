//import UIKit
//import CZUtils
//import CZNetworking
//import CZHttpFileCache
//
///**
// Web file manager maintains asynchronous web file downloading tasks.
// */
//@objc open class CZHttpFileManager: NSObject {
//
//    public static let shared: CZHttpFileManager = CZHttpFileManager()
//    private var downloader: CZImageDownloader
//    internal var cache: CZImageCache
//    
//    public override init() {
//      cache = CZImageCache()
//      downloader = CZImageDownloader(cache: cache)
//        super.init()
//    }
//    
//    public func downloadImage(with url: URL,
//                       cropSize: CGSize? = nil,
//                       priority: Operation.QueuePriority = .normal,
//                       completion: @escaping CZImageDownloderCompletion) {
//      cache.getCachedFile(with: url) { [weak self] (image) in
//            guard let `self` = self else { return }
//            if let image = image {
//                // Load from local disk
//                MainQueueScheduler.sync {
//                    completion(image, nil, true)
//                }
//                return
//            }
//            // Load from http service
//            self.downloader.downloadImage(with: url,
//                                          cropSize: cropSize,
//                                          priority: priority,
//                                          completion: completion)
//        }
//    }
//    
//    @objc(cancelDownloadWithURL:)
//    public func cancelDownload(with url: URL) {
//        downloader.cancelDownload(with: url)
//    }
//}
