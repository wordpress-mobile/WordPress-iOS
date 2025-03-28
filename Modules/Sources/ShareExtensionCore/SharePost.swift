import Foundation
import UIKit
import MobileCoreServices

/// A simple shared model to represent a Site
///
@objc public class ShareBlog: NSObject {
    @objc public static let typeIdentifier = "org.wordpress.share-blog"
}

/// A simple shared model to represent a post
///
/// This is a simplified version of a post used as a base for sharing amongst
/// the app, the Share extension, and other share options.
///
/// It supports NSCoding and can be imported/exported as NSData. It also defines
/// its own UTI data type.
///
@objc public class SharePost: NSObject, NSSecureCoding {
    @objc public static let typeIdentifier = "org.wordpress.share-post"
    @objc public static let activityType = UIActivity.ActivityType(rawValue: "org.wordpress.WordPressShare")

    @objc public let title: String?
    @objc public let summary: String?
    @objc public let url: URL?

    @objc public init(title: String?, summary: String?, url: String?) {
        self.title = title
        self.summary = summary
        self.url = url.flatMap(URL.init(string:))
        super.init()
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeString(forKey: .title)
        let summary = aDecoder.decodeString(forKey: .summary)
        let url = aDecoder.decodeString(forKey: .url)
        self.init(title: title, summary: summary, url: url)
    }

    @objc public convenience init?(data: Data) {
        do {
            let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
            self.init(coder: decoder)
        } catch {
            return nil
        }
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: .title)
        aCoder.encode(summary, forKey: .summary)
        aCoder.encode(url?.absoluteString, forKey: .url)
    }

    public static var supportsSecureCoding: Bool {
        return true
    }

    @objc public var content: String {
        var content = ""
        if let title {
            content.append("\(title)\n\n")
        }
        if let url {
            content.append(url.absoluteString)
        }
        return content
    }

    @objc public var data: Data {
        let encoder = NSKeyedArchiver(requiringSecureCoding: false)
        encode(with: encoder)
        encoder.finishEncoding()
        return encoder.encodedData
    }
}

extension SharePost {
    private func decode(coder: NSCoder, key: Key) -> String? {
        return coder.decodeObject(forKey: key.rawValue) as? String
    }

    private func encode(coder: NSCoder, string: String?, forKey key: Key) {
        guard let string else {
            return
        }
        coder.encode(string, forKey: key.rawValue)
    }

    enum Key: String {
        case title
        case summary
        case url
    }
}

private extension NSCoder {
    func encode(_ string: String?, forKey key: SharePost.Key) {
        guard let string else {
            return
        }
        encode(string, forKey: key.rawValue)
    }

    func decodeString(forKey key: SharePost.Key) -> String? {
        return decodeObject(forKey: key.rawValue) as? String
    }
}
