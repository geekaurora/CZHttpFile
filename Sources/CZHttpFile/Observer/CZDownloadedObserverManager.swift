import UIKit
import CZUtils
import CZNetworking

/**
 Protocol defines observer that observes downloading tasks.
 */
public protocol CZDownloadedObserverProtocol: class {
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL])
}

/**
 Manager maintains observers of downloaded states.
 
 - Note: It only holds weak reference to observers.
 */
public class CZDownloadedObserverManager {
  private lazy var observers = ThreadSafeWeakArray<CZDownloadedObserverProtocol>()
  
  public func publishDownloadedURLs(_ downloadingURLs: [URL]) {
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadingURLsDidUpdate(downloadingURLs)
      }
    }
  }
  
  public func addObserver(_ observer: CZDownloadedObserverProtocol) {
    observers.append(observer)
  }
  
  public func removeObserver(_ observer: CZDownloadedObserverProtocol) {
    observers.remove(observer)
  }
}
