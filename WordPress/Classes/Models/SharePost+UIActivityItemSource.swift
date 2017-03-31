import MobileCoreServices
import UIKit

extension SharePost: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url as Any
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        switch activityType {
        case SharePost.activityType:
            return data
        default:
            return url
        }
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return title ?? ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
        guard let activityType = activityType else {
            return kUTTypeURL as String
        }
        switch activityType {
        case SharePost.activityType:
            return SharePost.typeIdentifier
        default:
            return kUTTypeURL as String
        }
    }
}
