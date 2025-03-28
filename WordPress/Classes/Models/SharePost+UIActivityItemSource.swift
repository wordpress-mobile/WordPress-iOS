import MobileCoreServices
import UniformTypeIdentifiers
import UIKit
import ShareExtensionCore

extension SharePost: @retroactive UIActivityItemSource {
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url as Any
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case SharePost.activityType?:
            return data
        default:
            return url
        }
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title ?? ""
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        guard let activityType else {
            return UTType.url.identifier
        }
        switch activityType {
        case SharePost.activityType:
            return SharePost.typeIdentifier
        default:
            return UTType.url.identifier
        }
    }
}
