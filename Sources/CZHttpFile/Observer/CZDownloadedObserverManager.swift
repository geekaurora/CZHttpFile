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
  @ThreadSafe
  private var downloadedURLs: [URL] = []
  
  public func publishDownloadedURLs(_ downloadedURLs: [URL]) {
    dbgPrintWithFunc(self, "observers = \(observers.allObjects.count), downloadedURLs = \(downloadedURLs)")

    self._downloadedURLs.threadLock({ (_downloadedURLs) -> Void in
      _downloadedURLs = downloadedURLs
    })
    
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadedURLsDidUpdate(downloadedURLs)
      }
    }
  }
  
  public func addObserver(_ observer: CZDownloadedObserverProtocol) {
    dbgPrintWithFunc(self, "observer = \(observer)")
    
    // Append the observer.
    observers.append(observer)
    
    // Publish the latest state to observer.
    observer.downloadedURLsDidUpdate(downloadedURLs)
  }
  
  public func removeObserver(_ observer: CZDownloadedObserverProtocol) {
    observers.remove(observer)
  }
}
