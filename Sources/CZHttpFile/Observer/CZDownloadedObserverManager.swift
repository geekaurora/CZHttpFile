import UIKit
import CZUtils
import CZNetworking

/**
 Protocol defines observer that observes downloaded tasks.
 */
public protocol CZDownloadedObserverProtocol: class {
  func downloadedURLsDidUpdate(_ downloadedURLs: [URL])
}

/**
 Manager maintains observers of downloaded states.
 
 - Note: It only holds weak reference to observers.
 */
public class CZDownloadedObserverManager {
  private lazy var observers = ThreadSafeWeakArray<CZDownloadedObserverProtocol>()
  
  public func publishDownloadedURLs(_ downloadedURLs: [URL]) {
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadedURLsDidUpdate(downloadedURLs)
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
