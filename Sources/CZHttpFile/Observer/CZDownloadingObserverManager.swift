import UIKit
import CZUtils
import CZNetworking

/**
 Protocol defines observer that observes downloading tasks.
 */
public protocol CZDownloadingObserverProtocol: class {
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL])
}

/**
 Manager maintains observers of downloading states.
 
 - Note: It only holds weak reference to observers.
 */
public class CZDownloadingObserverManager {
  private lazy var observers = ThreadSafeWeakArray<CZDownloadingObserverProtocol>()
  @ThreadSafe
  private var downloadingURLs: [URL] = []
  
  public func publishDownloadingURLs(_ downloadingURLs: [URL]) {
    self._downloadingURLs.threadLock({ (actualDownloadingURLs) -> Void in
      actualDownloadingURLs = downloadingURLs
    })
    
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadingURLsDidUpdate(downloadingURLs)
      }
    }
  }
  
  public func addObserver(_ observer: CZDownloadingObserverProtocol) {
    // Publish the latest state to observer.
    observer.downloadingURLsDidUpdate(downloadingURLs)
    // Append the observer.
    observers.append(observer)
  }
  
  public func removeObserver(_ observer: CZDownloadingObserverProtocol) {
    observers.remove(observer)
  }
}
