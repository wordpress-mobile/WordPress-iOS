import Foundation
import SwiftUI
import WordPressShared
import WordPressKit
import AsyncImageKit
import WordPressUI

extension SiteIconViewModel {
    init(blog: Blog, size: Size = .regular) {
        self.init(size: size)

        self.firstLetter = blog.title?.first

        if blog.hasIcon, let icon = blog.icon {
            self.imageURL = SiteIconViewModel.optimizedURL(for: icon, imageSize: size.size, isP2: blog.isAutomatticP2)
            self.host = MediaHost(blog)
        }
    }

    init(readerSiteTopic: ReaderSiteTopic, size: Size = .regular) {
        self.init(size: size)

        self.firstLetter = readerSiteTopic.title.first
        self.imageURL = SiteIconViewModel.makeReaderSiteIconURL(
            iconURL: readerSiteTopic.siteBlavatar,
            siteID: readerSiteTopic.siteID.intValue,
            size: size.size
        )
    }
}

// MARK: - SiteIconViewModel (Optimized URL)

extension SiteIconViewModel {
    /// Returns the Size Optimized URL for a given Path.
    static func optimizedURL(for path: String, imageSize: CGSize = SiteIconViewModel.Size.regular.size, isP2: Bool = false) -> URL? {
        if isPhotonURL(path) || isDotcomURL(path) || isP2 {
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

    static func optimizedBlavatarURL(from path: String, imageSize: CGSize) -> URL? {
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

        if components.host == nil {
            return nil
        }

        return components.url
    }
}

// MARK: - SiteIconViewModel (Reader)

extension SiteIconViewModel {
    /// - parameter isBlavatar: A hint to skip the "is icon blavatar" check.
    /// - parameter size: Size in points.
    static func makeReaderSiteIconURL(iconURL: String?, isBlavatar: Bool = false, siteID: Int?, size: CGSize) -> URL? {
        guard let iconURL, !iconURL.isEmpty else {
            if let siteID {
                return getHardcodedSiteIconURL(siteID: siteID)
            }
            return nil
        }
        if isBlavatarURL(iconURL) {
            return optimizedBlavatarURL(from: iconURL, imageSize: size)
        }
        return URL(string: iconURL)
    }

    private static func getHardcodedSiteIconURL(siteID: Int) -> URL? {
        switch siteID {
        case 3584907:
            return Bundle.main.url(forResource: "wpcom-blog-icon", withExtension: "png")
        case 14607090:
            return Bundle.main.url(forResource: "wporg-blog-icon", withExtension: "png")
        default:
            return nil
        }
    }
}
