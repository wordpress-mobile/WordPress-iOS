import Foundation
import MobileCoreServices

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
        guard let type = typeIdentifier else {
            return nil
        }
        return URL.fileExtensionForUTType(type)
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

    /// The expected file extension string for a given UTType identifier string.
    ///
    /// - param type: The UTType identifier string.
    /// - returns: The expected file extension or nil if unknown.
    ///
    static func fileExtensionForUTType(_ type: String) -> String? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()
        return fileExtension as String?
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
        guard let uti = typeIdentifier,
            let mimeType = UTTypeCopyPreferredTagWithClass(uti as CFString, kUTTagClassMIMEType)?.takeUnretainedValue() as String?
            else {
                return "application/octet-stream"
        }

        return mimeType
    }

    var isVideo: Bool {
        guard let uti = typeIdentifier else {
            return false
        }

        return UTTypeConformsTo(uti as CFString, kUTTypeMovie)
    }

    var isImage: Bool {
        guard let uti = typeIdentifier else {
            return false
        }

        return UTTypeConformsTo(uti as CFString, kUTTypeImage)
    }

    var isGif: Bool {
        if let uti = typeIdentifier {
            return UTTypeConformsTo(uti as CFString, kUTTypeGIF)
        } else {
            return pathExtension.lowercased() == "gif"
        }
    }

    func appendingHideMasterbarParameters() -> URL? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return nil
        }
        // FIXME: This code is commented out because of a menu navigation issue that can occur while
        // viewing a site within the webview. See https://github.com/wordpress-mobile/WordPress-iOS/issues/9796
        // for more details.
        //
        // var queryItems = components.queryItems ?? []
        // queryItems.append(URLQueryItem(name: "preview", value: "true"))
        // queryItems.append(URLQueryItem(name: "iframe", value: "true"))
        // components.queryItems = queryItems
        /////
        return components.url
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

    @objc func appendingHideMasterbarParameters() -> NSURL? {
        let url = self as URL
        return url.appendingHideMasterbarParameters() as NSURL?
    }
}

extension URL {
    func appendingLocale() -> URL {
        guard let selfComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                return self
        }

        let localeIdentifier = Locale.current.identifier

        var newComponents = URLComponents()
        newComponents.scheme = selfComponents.scheme
        newComponents.host = selfComponents.host
        newComponents.path = selfComponents.path

        var selfQueryItems = selfComponents.queryItems ?? []

        let localeQueryItem = URLQueryItem(name: "locale", value: localeIdentifier)
        selfQueryItems.append(localeQueryItem)

        newComponents.queryItems = selfQueryItems

        return newComponents.url ?? self
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
