import UIKit

class SimpleImageDownloader {
    typealias Completion = (Data?) -> Void
    static let shared = SimpleImageDownloader()
    // private let imageCache = HTTPCache()
    
    func download(_ url: URL, completion: @escaping Completion) {
//        // Fetch from cache
//        if let data = imageCache.object(for: url) {
//            completion(data)
//            return
//        }
        
        // Fetch from network
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let `self` = self,
                let data = data else {
                    return
            }
            // Save to cache
            // self.imageCache.save(data, for: url)
          
            // completion
            completion(data)
        }.resume()
    }
}

private var imageKey: UInt8 = 0
extension UIImageView {
    var imageUrl: URL? {
        get { return objc_getAssociatedObject(self, &imageKey) as? URL }
        set { objc_setAssociatedObject(self, &imageKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func download(_ url: URL) {
        imageUrl = url
        SimpleImageDownloader.shared.download(url) { [weak self] (data) in
            guard let `self` = self else { return }
            guard let data = data,
                url == self.imageUrl else {
                    return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
            }
        }
    }
}
