import UIKit
import CZUtils
import CZNetworking

/**
 Manager maintains observers of downloading states.
 
 - Note: It only holds weak reference to observers.
 */
public class CZDownloadingObserverManager {
  private lazy var observers = ThreadSafeWeakArray<CZDownloadingObserverProtocol>()
  
  public func publishDownloadingURLs(_ downloadingURLs: [URL]) {
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadingURLsDidUpdate(downloadingURLs)
      }
    }
  }
  
  public func addObserver(_ observer: CZDownloadingObserverProtocol) {
    observers.append(observer)
  }
  
  public func removeObserver(_ observer: CZDownloadingObserverProtocol) {
    observers.remove(observer)
  }
}
