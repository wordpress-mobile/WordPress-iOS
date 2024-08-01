import Foundation
import SwiftUI
import WordPressShared

struct SiteIconViewModel {
    let imageURL: URL?
    let firstLetter: Character?
    let size: Size
    var background = Color(.secondarySystemBackground)

    enum Size {
        case small
        case regular

        var width: CGFloat {
            switch self {
            case .small: 24
            case .regular: 40
            }
        }

        var size: CGSize {
            CGSize(width: width, height: width)
        }
    }

    init(blog: Blog, size: Size = .regular) {
        self.size = size
        self.firstLetter = blog.title?.first

        if blog.hasIcon, let iconURL = blog.icon.flatMap(URL.init) {
            let targetSize = CGSize(width: size.width, height: size.width)
                .scaled(by: UITraitCollection.current.displayScale)
            self.imageURL = WPImageURLHelper.imageURLWithSize(targetSize, forImageURL: iconURL)
        } else {
            self.imageURL = nil
        }
    }
}

extension SiteIconViewModel {
    /// Returns the Size Optimized URL for a given Path.
    static func optimizedURL(for path: String, imageSize: CGSize = SiteIconViewModel.Size.regular.size) -> URL? {
        if isPhotonURL(path) || isDotcomURL(path) {
            return optimizedDotcomURL(from: path, imageSize: imageSize)
        }
        if isBlavatarURL(path) {
            return optimizedBlavatarURL(from: path, imageSize: imageSize)
        }
        return optimizedPhotonURL(from: path, imageSize: imageSize)
    }

    private static func optimizedDotcomURL(from path: String, imageSize: CGSize) -> URL? {
        let size = imageSize.scaled(by: UITraitCollection.current.displayScale)
        let query = String(format: "w=%d&h=%d", Int(size.width), Int(size.height))
        return parseURL(path: path, query: query)
    }

    private static func optimizedBlavatarURL(from path: String, imageSize: CGSize) -> URL? {
        let size = imageSize.scaled(by: UITraitCollection.current.displayScale)
        let query = String(format: "d=404&s=%d", Int(max(size.width, size.height)))
        return parseURL(path: path, query: query)
    }

    private static func optimizedPhotonURL(from path: String, imageSize: CGSize) -> URL? {
        guard let url = URL(string: path) else { return nil }
        return PhotonImageURLHelper.photonURL(with: imageSize, forImageURL: url)
    }

    /// Indicates if the received URL is hosted at WordPress.com
    ///
    private static func isDotcomURL(_ path: String) -> Bool {
        path.contains(".files.wordpress.com")
    }

    /// Indicates if the received URL is hosted at Gravatar.com
    ///
    private static func isBlavatarURL(_ path: String) -> Bool {
        path.contains("gravatar.com/blavatar")
    }

    /// Indicates if the received URL is a Photon Endpoint
    /// Possible matches are "i0.wp.com", "i1.wp.com" & "i2.wp.com" -> https://developer.wordpress.com/docs/photon/
    ///
    private static func isPhotonURL(_ path: String) -> Bool {
        path.contains(".wp.com")
    }

    /// Attempts to parse the URL contained within a Path, with a given query. Returns nil on failure.
    private static func parseURL(path: String, query: String) -> URL? {
        guard var components = URLComponents(string: path) else {
            return nil
        }
        components.query = query
        return components.url
    }
}
