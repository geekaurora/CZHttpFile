import UIKit
import CZUtils
import CZNetworking

public enum Constant {
  public static let webFileDownloadQueueName = "com.cz.webfile.download"
  public static let webFileDecodeQueueName = "com.cz.webfile.decode"
  public static var kOperations = "operations"
}

private var kvoContext: UInt8 = 0

/**
 Asynchronous webFile downloading class on top of OperationQueue
 */
public class CZWebFileDownloader<DataType: NSObjectProtocol>: NSObject {
  private let webFileDownloadQueue: OperationQueue
  private let webFileDecodeQueue: OperationQueue
  private let shouldObserveOperations: Bool
  private let cache: CZBaseWebFileCache<DataType>
  
  public init(cache: CZBaseWebFileCache<DataType>,
              downloadQueueMaxConcurrent: Int = CZWebFileDownloaderConstant.downloadQueueMaxConcurrent,
              decodeQueueMaxConcurrent: Int = CZWebFileDownloaderConstant.decodeQueueMaxConcurrent,
              errorDomain: String = CZWebFileDownloaderConstant.errorDomain,
              shouldObserveOperations: Bool = CZWebFileDownloaderConstant.shouldObserveOperations,
              webFileDownloadQueueName: String = Constant.webFileDownloadQueueName,
              webFileDecodeQueueName: String = Constant.webFileDecodeQueueName) {
    self.cache = cache
    self.shouldObserveOperations = shouldObserveOperations
    
    webFileDownloadQueue = OperationQueue()
    webFileDownloadQueue.name = webFileDownloadQueueName
    webFileDownloadQueue.qualityOfService = .userInteractive
    webFileDownloadQueue.maxConcurrentOperationCount = downloadQueueMaxConcurrent
    
    webFileDecodeQueue = OperationQueue()
    webFileDownloadQueue.name = webFileDecodeQueueName
    webFileDecodeQueue.maxConcurrentOperationCount = decodeQueueMaxConcurrent
    super.init()
    
    if shouldObserveOperations {
      webFileDownloadQueue.addObserver(self, forKeyPath: Constant.kOperations, options: [.new, .old], context: &kvoContext)
    }
  }
  
  deinit {
    if shouldObserveOperations {
      webFileDownloadQueue.removeObserver(self, forKeyPath: Constant.kOperations)
    }
    webFileDownloadQueue.cancelAllOperations()
  }
  
  /// Download the http file with the desired params.
  ///
  /// - Parameters:
  ///   - decodeData: Closure used to decode `Data` to tuple (DataType?, Data?). If is nil, then returns `Data` directly.
  public func downloadWebFile(with url: URL?,
                               priority: Operation.QueuePriority = .normal,
                               decodeData: ((Data) -> (DataType?, Data?)?)?,
                               completion: @escaping (_ webFile: DataType?, _ error: Error?, _ fromCache: Bool) -> Void) {
    guard let url = url else { return }
    cancelDownload(with: url)
    
    let operation = WebFileDownloadOperation(
      url: url,
      progress: nil,
      success: { [weak self] (task, data) in
        guard let `self` = self, let data = data else {
          completion(nil, WebWebFileError.invalidData, false)
          return
        }
        // Decode/crop webFile in decode OperationQueue
        self.webFileDecodeQueue.addOperation {
          guard let (outputWebFile, ouputData) = (decodeData?(data)).assertIfNil else {
            completion(nil, WebWebFileError.invalidData, false)
            return
          }
          // let (outputWebFile, ouputData) = self.cropWebFileIfNeeded(webFile, data: data, cropSize: cropSize)
          
          // Save downloaded file to cache.
          self.cache.setCacheFile(withUrl: url, data: ouputData)
          // CZImageCache.shared.setCacheFile(withUrl: url, data: ouputData)
          
          // Call completion on mainQueue
          MainQueueScheduler.async {
            completion(outputWebFile, nil, false)
          }
          
        }
      }, failure: { (task, error) in
        completion(nil, error, false)
      })
    operation.queuePriority = priority
    webFileDownloadQueue.addOperation(operation)
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL?) {
    guard let url = url else { return }
    
    let cancelIfNeeded = { (operation: Operation) in
      if let operation = operation as? WebFileDownloadOperation,
         operation.url == url {
        operation.cancel()
      }
    }
    webFileDownloadQueue.operations.forEach(cancelIfNeeded)
  }
  
  // MARK: - KVO Delegation
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard context == &kvoContext,
          let object = object as? OperationQueue,
          let keyPath = keyPath,
          keyPath == Constant.kOperations else {
      return
    }
    if object === webFileDownloadQueue {
      CZUtils.dbgPrint("[CZWebFileDownloader] Queued tasks: \(object.operationCount)")
    }
  }
}
