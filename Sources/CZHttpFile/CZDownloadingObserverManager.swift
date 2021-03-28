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
 Manager maintains observers of download states.
 - Note: It only holds weak reference to observers.
 */
public class CZDownloadingObserverManager {
  private lazy var observers = ThreadSafeWeakArray<CZDownloadingObserverProtocol>()
  
  public func publishDownloadingURLs(_ downloadingURLs: [URL]) {
    observers.allObjects.forEach { $0.downloadingURLsDidUpdate(downloadingURLs) }
  }
  
  public func addObserver(_ observer: CZDownloadingObserverProtocol) {
    observers.append(observer)
  }
  
  public func removeObserver(_ observer: CZDownloadingObserverProtocol) {
    observers.remove(observer)
  }
}
