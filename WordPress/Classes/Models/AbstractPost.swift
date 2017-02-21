import Foundation

extension AbstractPost {
    class func title(for status: Status) -> String {
        return AbstractPost.title(forStatus: status.rawValue)
    }
}
