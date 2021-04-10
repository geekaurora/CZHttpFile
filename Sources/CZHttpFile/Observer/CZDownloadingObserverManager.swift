import UIKit
import CZUtils
import CZNetworking

/**
 Protocol defines observer that observes downloading tasks.
 */
public protocol CZDownloadingObserverProtocol: class {
  func downloadingURLsDidUpdate(_ downloadingURLs: [URL])
  
  func downloadingProgressDidUpdate(_ downloadingProgressDict: CZDownloadingObserverManager.DownloadingProgressDict)
}

/**
 Manager maintains observers of downloading states.
 
 - Note: It only holds weak reference to observers.
 */
public class CZDownloadingObserverManager {
  internal private(set) lazy var observers = ThreadSafeWeakArray<CZDownloadingObserverProtocol>()
  
  /// Thread safe download URLs.
  @ThreadSafe
  private var downloadingURLs: [URL] = []
  
  /// Thread safe downloading progress dictionary - [downloadingURL: DownloadingProgress].
  public typealias DownloadingProgressDict = [URL: DownloadingProgress]
  @ThreadSafe
  private var downloadingProgressDict = DownloadingProgressDict()
  
  // MARK: - Publish
  
  public func publishDownloadingURLs(_ downloadingURLs: [URL]) {
    _downloadingURLs.threadLock { _downloadingURLs in
      _downloadingURLs = downloadingURLs
    }
    
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadingURLsDidUpdate(downloadingURLs)
      }
    }
    // Update downloadingProgressDict with updated `downloadingURLs` to filter removed URLs out.
    updateDownloadingProgressDict()
  }
  
  public func publishDownloadingProgress(url: URL, progress: Double) {
    _downloadingProgressDict.threadLock { _downloadingProgressDict in
      _downloadingProgressDict[url] = DownloadingProgress(url: url, progress: progress)
    }
    publishDownloadingProgressToObservers()
  }
  
  // MARK: - Observer
  
  public func addObserver(_ observer: CZDownloadingObserverProtocol) {
    // Publish the latest State to observer.
    observer.downloadingURLsDidUpdate(downloadingURLs)
    // Append the observer.
    observers.append(observer)
  }
  
  public func removeObserver(_ observer: CZDownloadingObserverProtocol) {
    observers.remove(observer)
  }
}

// MARK: - Private methods

private extension CZDownloadingObserverManager {
  func updateDownloadingProgressDict() {
    let downloadingURLsSet = Set(downloadingURLs)
    guard downloadingURLsSet != Set(downloadingProgressDict.keys) else {
      return
    }
    _downloadingProgressDict.threadLock { _downloadingProgressDict in
      _downloadingProgressDict = _downloadingProgressDict.filter { downloadingURLsSet.contains($0.key) }
    }
    publishDownloadingProgressToObservers()
  }
  
  func publishDownloadingProgressToObservers() {
    MainQueueScheduler.safeAsync {
      self.observers.allObjects.forEach {
        $0.downloadingProgressDidUpdate(self.downloadingProgressDict)
      }
    }
  }
}

