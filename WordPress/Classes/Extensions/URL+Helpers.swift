import Foundation
import MobileCoreServices
import UniformTypeIdentifiers

extension URL {

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

    /// Returns a URL with an incremental file name, if a file already exists at the given URL.
    ///
    /// Previously seen in MediaService.m within urlForMediaWithFilename:andExtension:
    ///
    func incrementalFilename() -> URL {
        var url = self
        let pathExtension = url.pathExtension
        let filename = url.deletingPathExtension().lastPathComponent
        var index = 1
        let fileManager = FileManager.default
        while fileManager.fileExists(atPath: url.path) {
            let incrementedName = "\(filename)-\(index)"
            url.deleteLastPathComponent()
            url.appendPathComponent(incrementedName, isDirectory: false)
            url.appendPathExtension(pathExtension)
            index += 1
        }
        return url
    }

    var pixelSize: CGSize {
        get {
            if isVideo {
                let asset = AVAsset(url: self as URL)
                if let track = asset.tracks(withMediaType: .video).first {
                    return track.naturalSize.applying(track.preferredTransform)
                }
            } else if isImage {
                let options: [NSString: NSObject] = [kCGImageSourceShouldCache: false as CFBoolean]
                if
                    let imageSource = CGImageSourceCreateWithURL(self as NSURL, nil),
                    let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, options as CFDictionary?) as NSDictionary?,
                    let pixelWidth = imageProperties[kCGImagePropertyPixelWidth as NSString] as? Int,
                    let pixelHeight = imageProperties[kCGImagePropertyPixelHeight as NSString] as? Int
                {
                    return CGSize(width: pixelWidth, height: pixelHeight)
                }
            }
            return CGSize.zero
        }
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
        guard let host = host else {
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

    /// Handle the common link protocols.
    /// - tel: open a prompt to call the phone number
    /// - sms: compose new message in iMessage app
    /// - mailto: compose new email in Mail app
    ///
    var isLinkProtocol: Bool {
        guard let urlScheme = scheme else {
            return false
        }

        let linkProtocols = ["tel", "sms", "mailto"]
        if linkProtocols.contains(urlScheme) && UIApplication.shared.canOpenURL(self) {
            return true
        }

        return false
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

extension NSURL {
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

extension URL {
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
}
