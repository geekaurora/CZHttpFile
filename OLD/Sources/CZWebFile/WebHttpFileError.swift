import UIKit
import CZUtils
import CZNetworking

/// Error class for CZWebWebFile
open class WebWebFileError: CZError {
    static let invalidData = WebWebFileError("Invalid webFile data.")
    
    public init(_ description: String? = nil, code: Int = -99) {
        super.init(domain: CZWebFileDownloaderConstant.errorDomain, code: code, description: description)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
