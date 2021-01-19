import Foundation
import MobileCoreServices

/// A simple shared model to represent a Site
///
@objc class ShareBlog: NSObject {
    @objc static let typeIdentifier = "org.wordpress.share-blog"
}

/// A simple shared model to represent a post
///
/// This is a simplified version of a post used as a base for sharing amongst
/// the app, the Share extension, and other share options.
///
/// It supports NSCoding and can be imported/exported as NSData. It also defines
/// its own UTI data type.
///
@objc class SharePost: NSObject, NSSecureCoding {
    @objc static let typeIdentifier = "org.wordpress.share-post"
    @objc static let activityType = UIActivity.ActivityType(rawValue: "org.wordpress.WordPressShare")

    @objc let title: String?
    @objc let summary: String?
    @objc let url: URL?

    @objc init(title: String?, summary: String?, url: String?) {
        self.title = title
        self.summary = summary
        self.url = url.flatMap(URL.init(string:))
        super.init()
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeString(forKey: .title)
        let summary = aDecoder.decodeString(forKey: .summary)
        let url = aDecoder.decodeString(forKey: .url)
        self.init(title: title, summary: summary, url: url)
    }

    @objc convenience init?(data: Data) {
        do {
            let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
            self.init(coder: decoder)
        } catch {
            return nil
        }
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: .title)
        aCoder.encode(summary, forKey: .summary)
        aCoder.encode(url?.absoluteString, forKey: .url)
    }

    static var supportsSecureCoding: Bool {
        return true
    }

    @objc var content: String {
        var content = ""
        if let title = title {
            content.append("\(title)\n\n")
        }
        if let url = url {
            content.append(url.absoluteString)
        }
        return content
    }

    @objc var data: Data {
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
        guard let string = string else {
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
        guard let string = string else {
            return
        }
        encode(string, forKey: key.rawValue)
    }

    func decodeString(forKey key: SharePost.Key) -> String? {
        return decodeObject(forKey: key.rawValue) as? String
    }
}
