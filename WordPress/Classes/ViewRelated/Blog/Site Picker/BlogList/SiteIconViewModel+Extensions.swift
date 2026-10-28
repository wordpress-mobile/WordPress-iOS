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
            let isP2 = blog.isAutomatticP2
            self.imageURL = icon
            self.sizeImageURL = { url, displayScale in
                SiteIconViewModel.optimizedURL(
                    for: url,
                    imageSize: size.size,
                    isP2: isP2,
                    traitCollection: UITraitCollection(displayScale: displayScale)
                )
            }
            self.host = MediaHost(blog)
        }
    }

    init(readerSiteTopic: ReaderSiteTopic, size: Size = .regular) {
        self.init(size: size)

        self.firstLetter = readerSiteTopic.title.first
        self.imageURL = SiteIconViewModel.makeReaderSiteIconURL(
            iconURL: readerSiteTopic.siteBlavatar,
            siteID: readerSiteTopic.siteID.intValue
        )
        if imageURL != nil {
            self.sizeImageURL = { url, displayScale in
                SiteIconViewModel.sizeReaderSiteIconURL(
                    url,
                    size: size.size,
                    traitCollection: UITraitCollection(displayScale: displayScale)
                )
            }
        }
    }
}

// MARK: - SiteIconViewModel (Optimized URL)

extension SiteIconViewModel {
    /// Returns the size-optimized URL for a given URL.
    /// - parameter traitCollection: The trait collection of the view that displays the icon.
    static func optimizedURL(
        for url: URL,
        imageSize: CGSize = SiteIconViewModel.Size.regular.size,
        isP2: Bool = false,
        traitCollection: UITraitCollection
    ) -> URL? {
        if url.isWordPressComHost || isP2 {
            return optimizedDotcomURL(from: url, imageSize: imageSize, traitCollection: traitCollection)
        }
        if isBlavatarURL(url) {
            return optimizedBlavatarURL(from: url, imageSize: imageSize, traitCollection: traitCollection)
        }
        return optimizedPhotonURL(from: url, imageSize: imageSize, traitCollection: traitCollection)
    }

    private static func optimizedDotcomURL(
        from url: URL,
        imageSize: CGSize,
        traitCollection: UITraitCollection
    ) -> URL? {
        let size = imageSize.scaled(by: traitCollection.displayScale)
        let query = String(format: "w=%d&h=%d", Int(size.width), Int(size.height))
        return parseURL(url: url, query: query)
    }

    private static func optimizedBlavatarURL(
        from url: URL,
        imageSize: CGSize,
        traitCollection: UITraitCollection
    ) -> URL? {
        let size = imageSize.scaled(by: traitCollection.displayScale)
        let query = String(format: "d=404&s=%d", Int(max(size.width, size.height)))
        return parseURL(url: url, query: query)
    }

    private static func optimizedPhotonURL(
        from url: URL,
        imageSize: CGSize,
        traitCollection: UITraitCollection
    ) -> URL? {
        PhotonImageURLHelper.photonURL(with: imageSize, forImageURL: url, traitCollection: traitCollection)
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
    /// - parameters:
    ///   - size: Size in points.
    ///   - traitCollection: The trait collection of the view that displays the icon.
    static func makeReaderSiteIconURL(
        iconURL: String?,
        siteID: Int?,
        size: CGSize,
        traitCollection: UITraitCollection
    ) -> URL? {
        guard let url = makeReaderSiteIconURL(iconURL: iconURL, siteID: siteID) else {
            return nil
        }
        return sizeReaderSiteIconURL(url, size: size, traitCollection: traitCollection)
    }

    /// Returns the URL of the site icon before it's sized for a display.
    private static func makeReaderSiteIconURL(iconURL: String?, siteID: Int?) -> URL? {
        guard let iconURL, !iconURL.isEmpty else {
            if let siteID {
                return getHardcodedSiteIconURL(siteID: siteID)
            }
            return nil
        }
        return URL(string: iconURL)
    }

    /// Sizes Gravatar blavatars for the display. Other URLs are returned as is.
    private static func sizeReaderSiteIconURL(
        _ url: URL,
        size: CGSize,
        traitCollection: UITraitCollection
    ) -> URL? {
        guard isBlavatarURL(url) else {
            return url
        }
        return optimizedBlavatarURL(from: url, imageSize: size, traitCollection: traitCollection)
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
