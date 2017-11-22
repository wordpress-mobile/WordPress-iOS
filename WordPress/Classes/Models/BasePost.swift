import CoreData

extension BasePost {
    // We can't use #keyPath on a non-@objc property, and we can't expose
    // status to Objc-C since it returns an optional enum.
    // I'd prefer #keyPath over a string constant, but the enum brings way more value.
    static let statusKeyPath = "status"
    var status: Status? {
        get {
            return rawValue(forKey: BasePost.statusKeyPath)
        }
        set {
            setRawValue(newValue, forKey: BasePost.statusKeyPath)
        }
    }

    /// For Obj-C compatibility only
    @objc(status)
    var statusString: String? {
        get {
            return status?.rawValue
        }
        set {
            status = newValue.flatMap({ Status(rawValue: $0) })
        }
    }

    enum Status: String {
        case draft = "draft"
        case pending = "pending"
        case publishPrivate = "private"
        case publish = "publish"
        case scheduled = "future"
        case trash = "trash"
        case deleted = "deleted" // Returned by wpcom REST API when a post is permanently deleted.
    }
}

extension Sequence where Iterator.Element == BasePost.Status {
    var strings: [String] {
        return map({ $0.rawValue })
    }
}
