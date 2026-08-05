import Foundation
import SwiftUI
import WordPressData
import WordPressShared
import WordPressKit
import AsyncImageKit
import WordPressUI

extension SiteIconViewModel {
    init(blog: Blog, size: Size = .regular) {
        self.init(size: size)

        self.firstLetter = blog.title?.first

        if let icon = blog.iconURL {
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
    /// Returns the size-optimized URL for a given URL.
    static func optimizedURL(
        for url: URL,
        imageSize: CGSize = SiteIconViewModel.Size.regular.size,
        isP2: Bool = false
    ) -> URL? {
        if url.isWordPressComHost || isP2 {
            return optimizedDotcomURL(from: url, imageSize: imageSize)
        }
        if isBlavatarURL(url) {
            return optimizedBlavatarURL(from: url, imageSize: imageSize)
        }
        return optimizedPhotonURL(from: url, imageSize: imageSize)
    }

    private static func optimizedDotcomURL(from url: URL, imageSize: CGSize) -> URL? {
        let size = imageSize.scaled(by: UITraitCollection.current.displayScale)
        let query = String(format: "w=%d&h=%d", Int(size.width), Int(size.height))
        return parseURL(url: url, query: query)
    }

    static func optimizedBlavatarURL(from url: URL, imageSize: CGSize) -> URL? {
        let size = imageSize.scaled(by: UITraitCollection.current.displayScale)
        let query = String(format: "d=404&s=%d", Int(max(size.width, size.height)))
        return parseURL(url: url, query: query)
    }

    private static func optimizedPhotonURL(from url: URL, imageSize: CGSize) -> URL? {
        PhotonImageURLHelper.photonURL(with: imageSize, forImageURL: url)
    }

    /// Indicates if the received URL is a Gravatar blavatar. Matches the host exactly or as
    /// a subdomain, never as a substring, so a lookalike URL can't skip the Photon proxy.
    ///
    private static func isBlavatarURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else {
            return false
        }
        return (host == "gravatar.com" || host.hasSuffix(".gravatar.com")) && url.path.hasPrefix("/blavatar")
    }

    /// Attempts to update a URL with a given query. Returns nil on failure.
    private static func parseURL(url: URL, query: String) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
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
        guard let url = URL(string: iconURL) else {
            return nil
        }
        if isBlavatarURL(url) {
            return optimizedBlavatarURL(from: url, imageSize: size)
        }
        return url
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
