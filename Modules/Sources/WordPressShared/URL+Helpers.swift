import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

public extension URL {

    struct Helpers {
        public static func temporaryFile(named name: String = UUID().uuidString) -> URL {
            if #available(iOS 16.0, *) {
                return URL.temporaryDirectory.appending(path: name)
            } else {
                return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
            }
        }

        public static func temporaryDirectory(named name: String) -> URL {
            if #available(iOS 16.0, *) {
                return URL.temporaryDirectory.appending(path: name, directoryHint: .isDirectory)
            } else {
                return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name, isDirectory: true)
            }
        }
    }

    /// The URLResource fileSize of the file at the URL in bytes, if available.
    ///
    var fileSize: Int64? {
        guard isFileURL else {
            return nil
        }
        let values = try? resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values?.allValues[.fileSizeKey] as? NSNumber else {
            return nil
        }
        return fileSize.int64Value
    }

    /// The URLResource uniform type identifier for the file at the URL, if available.
    ///
    var typeIdentifier: String? {
        let values = try? resourceValues(forKeys: [.typeIdentifierKey])
        return values?.typeIdentifier
    }

    var typeIdentifierFileExtension: String? {
        contentType?.preferredFilenameExtension
    }

    var mimeType: String {
        contentType?.preferredMIMEType ?? "application/octet-stream"
    }

    private var contentType: UTType? {
        typeIdentifier.flatMap(UTType.init)
    }

    var isVideo: Bool {
        contentType?.conforms(to: .movie) ?? false
    }

    var isImage: Bool {
        contentType?.conforms(to: .image) ?? false
    }

    var isGif: Bool {
        if let type = contentType {
            return type.conforms(to: .gif)
        } else {
            return pathExtension.lowercased() == "gif"
        }
    }

    var isHostedAtWPCom: Bool {
        guard let host else {
            return false
        }

        return host.hasSuffix(".wordpress.com")
    }

    var isWordPressDotComPost: Bool {
        // year, month, day, slug
        let components = pathComponents.filter({ $0 != "/" })
        return components.count == 4 && isHostedAtWPCom
    }

    var isWPComEmoji: Bool {
        absoluteString.contains(".wp.com/i/emojis")
    }

    /// Does a quick test to see if 2 urls are equal to each other by
    /// using just the hosts and paths. This ignores any query items, or hashes
    /// on the urls
    func isHostAndPathEqual(to url: URL) -> Bool {
        guard
            let components1 = URLComponents(url: self, resolvingAgainstBaseURL: true),
            let components2 = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            return false
        }

        let check1 = (components1.host ?? "") + components1.path
        let check2 = (components2.host ?? "") + components2.path

        return check1 == check2
    }
}

public extension NSURL {
    @objc var isVideo: Bool {
        return (self as URL).isVideo
    }

    @objc var fileSize: NSNumber? {
        guard let fileSize = (self as URL).fileSize else {
            return nil
        }
        return NSNumber(value: fileSize)
    }

}

public extension URL {
    /// Appends query items to the URL.
    /// - Parameter newQueryItems: The new query items to add to the URL. These will **not** overwrite any existing items but are appended to the existing list.
    /// - Returns: The URL with added query items.
    func appendingQueryItems(_ newQueryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(contentsOf: newQueryItems)
        components?.queryItems = queryItems
        return components?.url ?? self
    }

    /// Gravatar doesn't support "Cache-Control: none" header. So we add a random query parameter to
    /// bypass the backend cache and get the latest image.
    func appendingGravatarCacheBusterParam() -> URL {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)
        if urlComponents?.queryItems == nil {
            urlComponents?.queryItems = []
        }
        urlComponents?.queryItems?.append(.init(name: "_", value: "\(NSDate().timeIntervalSince1970)"))
        return urlComponents?.url ?? self
    }
}
