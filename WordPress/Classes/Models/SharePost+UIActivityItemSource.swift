import MobileCoreServices
import UIKit

extension SharePost: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url as Any
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        switch activityType {
        case UIActivityType.mail:
            return url
        case SharePost.activityType:
            return data
        default:
            return content
        }
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return title ?? ""
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String {
        guard let activityType = activityType else {
            return kUTTypePlainText as String
        }
        switch activityType {
        case UIActivityType.mail:
            return kUTTypeURL as String
        case SharePost.activityType:
            return SharePost.typeIdentifier
        default:
            return kUTTypePlainText as String
        }
    }
}
