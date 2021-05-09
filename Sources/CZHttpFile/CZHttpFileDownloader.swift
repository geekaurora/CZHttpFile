import UIKit
import CZUtils
import CZNetworking

public enum Constant {
  public static let httpFileDownloadQueueName = "com.cz.httpfile.download"
  public static let httpFileDecodeQueueName = "com.cz.httpfile.decode"
  public static var operationsKeyPath = "operations"
}

private var kvoContext: UInt8 = 0

/**
 Asynchronous http file downloading class on top of OperationQueue.
 */
public class CZHttpFileDownloader<DataType: NSObjectProtocol>: NSObject {
  public typealias Completion = (_ httpFile: DataType?, _ error: Error?, _ fromCache: Bool) -> Void
  
  /// Closure that decodes `inputData` to `(decodedData: DataType?, decodedMetadata: Data?)` tuple.
  /// - Note: `decodedData` is  the decoded data type `DataType`. e.g. UIImage.
  ///         `decodedMetadata` is NSData format of `decodedData`.
  public typealias DecodeData = (_ inputData: Data) -> (decodedData: DataType?, decodedMetadata: Data?)?
  
  private let httpFileDownloadQueue: OperationQueue
  private let httpFileDecodeQueue: OperationQueue
  private let shouldObserveOperations: Bool
  private let cache: CZBaseHttpFileCache<DataType>
  private weak var downloadingObserverManager: CZDownloadingObserverManager?
  
  @ThreadSafe public private(set) var downloadingURLs: [URL] = []
  
  public init(cache: CZBaseHttpFileCache<DataType>,
              downloadingObserverManager: CZDownloadingObserverManager? = nil,
              downloadQueueMaxConcurrent: Int = CZHttpFileDownloaderConfig.downloadQueueMaxConcurrent,
              decodeQueueMaxConcurrent: Int = CZHttpFileDownloaderConfig.decodeQueueMaxConcurrent,
              errorDomain: String = CZHttpFileDownloaderConfig.errorDomain,
              shouldObserveOperations: Bool = CZHttpFileDownloaderConfig.shouldObserveOperations,
              httpFileDownloadQueueName: String = Constant.httpFileDownloadQueueName,
              httpFileDecodeQueueName: String = Constant.httpFileDecodeQueueName) {
    self.cache = cache
    self.downloadingObserverManager = downloadingObserverManager
    self.shouldObserveOperations = shouldObserveOperations
    
    httpFileDownloadQueue = OperationQueue()
    httpFileDownloadQueue.name = httpFileDownloadQueueName
    // .default QoS: between .userInteractive and .utility.
    httpFileDownloadQueue.qualityOfService = .default
    // httpFileDownloadQueue.maxConcurrentOperationCount = downloadQueueMaxConcurrent
    
    httpFileDecodeQueue = OperationQueue()
    httpFileDownloadQueue.name = httpFileDecodeQueueName
    // httpFileDecodeQueue.maxConcurrentOperationCount = decodeQueueMaxConcurrent
    super.init()
    
    // if shouldObserveOperations {
    httpFileDownloadQueue.addObserver(
      self,
      forKeyPath: Constant.operationsKeyPath,
      options: [.new, .old],
      context: &kvoContext)
  }
  
  deinit {
    // if shouldObserveOperations {
    httpFileDownloadQueue.removeObserver(self, forKeyPath: Constant.operationsKeyPath)
    httpFileDownloadQueue.cancelAllOperations()
  }
  
  /// Download the http file with the input params.
  ///
  /// - Parameters:
  ///   - decodeData: Closure used to decode `Data` to tuple (DataType?, Data?). If is nil, then returns `Data` directly.
  public func downloadHttpFile(url: URL?,
                               priority: Operation.QueuePriority = .normal,
                               decodeData: DecodeData? = nil,
                               progress: HTTPRequestWorker.Progress? = nil,
                               completion: @escaping Completion) {
    guard let url = url else { return }
    
    /*
    SimpleImageDownloader.shared.download(url) { (data: Data?) in
      guard let data = data.assertIfNil else { return }
      
      var outputHttpFile: DataType? = data as? DataType
      var ouputData: Data? = data
      
      // Decode from `data` to `(outputHttpFile, ouputData)` if applicable.
      if let decodeData = decodeData {
        guard let (decodedHttpFile, decodedData) = decodeData(data).assertIfNil else {
          completion(nil, WebHttpFileError.invalidData, false)
          return
        }
        (outputHttpFile, ouputData) = (decodedHttpFile, decodedData)
      }
      
      MainQueueScheduler.async {
         completion(outputHttpFile, nil, false)
      }
    }
    */
    
    // cancelDownload(with: url)
    let operation = HttpFileDownloadOperation(
      url: url,
      progress: progress,
      success: { [weak self] (task, data) in
        guard let `self` = self, let data = data else {
          completion(nil, WebHttpFileError.invalidData, false)
          return
        }
        
        // Decode Data to httpFile in OperationQueue.
        // If `decodeData` closure is nil, returns `data` directly without decoding.
        // - Note: you may customize decoding with additional work. e.g. Decode to UIImage and then crop.
        self.httpFileDecodeQueue.addOperation {
          var outputHttpFile: DataType? = data as? DataType
          var ouputData: Data? = data
          
          // Decode from `data` to `(outputHttpFile, ouputData)` if applicable.
          if let decodeData = decodeData {
            guard let (decodedHttpFile, decodedData) = decodeData(data).assertIfNil else {
              completion(nil, WebHttpFileError.invalidData, false)
              return
            }
            (outputHttpFile, ouputData) = (decodedHttpFile, decodedData)
          }
          
          MainQueueScheduler.async {
            completion(outputHttpFile, nil, false)
          }
          
          // Save downloaded file to cache.
//          self.cache.setCacheFile(
//            withUrl: url,
//            data: ouputData,
//            completeSetCachedItemsDict: {
//              // Call completion on mainQueue - after setting CachedItems info to ensure downloaded state.
//              MainQueueScheduler.async {
//                completion(outputHttpFile, nil, false)
//              }
//            })
        }
      }, failure: { (task, error) in
        CZSystemInfo.getURLSessionInfo()
        assertionFailure("Failed to download file. url = \(url), Error - \(error)")
        completion(nil, error, false)
      })
    operation.queuePriority = priority
    httpFileDownloadQueue.addOperation(operation)
 
  }
  
  @objc(cancelDownloadWithURL:)
  public func cancelDownload(with url: URL?) {
    guard let url = url else { return }
    
    let cancelIfNeeded = { (operation: Operation) in
      if let operation = operation as? HttpFileDownloadOperation,
         operation.url == url {
        operation.cancel()
      }
    }
    httpFileDownloadQueue.operations.forEach(cancelIfNeeded)
  }
  
  // MARK: - KVO Delegation
  
  public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    guard context == &kvoContext,
          let object = object as? OperationQueue,
          let keyPath = keyPath,
          keyPath == Constant.operationsKeyPath else {
      return
    }
    if object === httpFileDownloadQueue {
      if let fileDownloadOperations = object.operations as? [HttpFileDownloadOperation] {
        _downloadingURLs.threadLock { downloadingURLs in
          downloadingURLs = fileDownloadOperations.map(\.url)
        }
        downloadingObserverManager?.publishDownloadingURLs(downloadingURLs)
      }
      
      if shouldObserveOperations {
        //dbgPrint("[CZHttpFileDownloader] Queued tasks: \(object.operationCount), currentThread = \(Thread.current), downloadingURLs = \(downloadingURLs)")
        CZSystemInfo.getURLSessionInfo()
        dbgPrint("[CZHttpFileDownloader] Queued tasks: \(object.operationCount), Executing tasks: \(object.operations.count), currentThread = \(Thread.current)")
      }
    }
  }
}
