import Foundation
import CZUtils
import CZNetworking

/**
 Concurrent operation class for httpFile downloading OperationQueue, supports success/failure/progress callback
 */
class HttpFileDownloadOperation: ConcurrentBlockOperation {
  
  private var requester: HTTPRequestWorker?
  private let progress: HTTPRequestWorker.Progress?
  private var success: HTTPRequestWorker.Success?
  private var failure: HTTPRequestWorker.Failure?
  let url: URL
  
  required init(url: URL,
                progress: HTTPRequestWorker.Progress? = nil,
                success: HTTPRequestWorker.Success?,
                failure: HTTPRequestWorker.Failure?) {
    self.url = url
    self.progress = progress
    super.init()
    
    self.props["url"] = url
    self.success = { [weak self] (task, data) in
      // Update Operation's `isFinished` prop
      self?.finish()
      success?(task, data)
    }
    
    self.failure = { [weak self] (task, error) in
      // Update Operation's `isFinished` prop
      self?.finish()
      failure?(task, error)
    }
  }  
  
  override func _execute() {
    downloadHttpFile(url: url)
  }
  
  override func cancel() {
    super.cancel()
    requester?.cancel()
  }
  
}

private extension HttpFileDownloadOperation {
  func downloadHttpFile(url: URL) {
    if (false) {
      
      // * TEST - Fixed crash!
      URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
        guard let `self` = self else { return }
        if let error = error {
          self.failure?(nil, error)
          return
        }
         self.success?(nil, data)
      }.resume()
      
//      URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
//        guard let `self` = self else { return }
//        // * Add MainQueueScheduler.
//        MainQueueScheduler.async {
//          if let error = error {
//            self.failure?(nil, error)
//            return
//          }
//          self.success?(nil, data)
//        }
//      }.resume()
    
    } else {
      
      // * Crash.
      CZHTTPManager.shared.GET(
        url.absoluteString,
        shouldSerializeJson: false,
        success: success,
        failure: failure,
        progress: progress)
      
//      requester = HTTPRequestWorker(
//        .GET,
//        url: url,
//        params: nil,
//        shouldSerializeJson: false,
//        success: success,
//        failure: failure,
//        progress: progress)
//      requester?.start()
      
      // requester?.testStartFetch()
    }
  }
}




