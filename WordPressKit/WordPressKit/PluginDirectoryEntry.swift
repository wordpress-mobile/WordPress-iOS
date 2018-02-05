import Foundation

public struct PluginDirectoryEntry: Equatable {
    public let name: String
    public let slug: String
    public let version: String?
    public let lastUpdated: Date?

    public let icon: URL?
    public let banner: URL?

    public let author: String
    public let authorURL: URL?

    private let descriptionHTML: String?
    private let installationHTML: String?
    private let faqHTML: String?
    private let changelogHTML: String?

    public var descriptionText: NSAttributedString? { return extractHTMLText(self.descriptionHTML) }
    public var installationText: NSAttributedString? { return extractHTMLText(self.installationHTML) }
    public var faqText: NSAttributedString?  { return extractHTMLText(self.faqHTML) }
    public var changelogText: NSAttributedString? { return extractHTMLText(self.changelogHTML) }

    private let rating: Int
    public var starRating: Int { return Int((Double(rating) / 20).rounded()) }


    public static func ==(lhs: PluginDirectoryEntry, rhs: PluginDirectoryEntry) -> Bool {
        return lhs.name == rhs.name
            && lhs.slug == rhs.slug
            && lhs.version == rhs.version
            && lhs.lastUpdated == rhs.lastUpdated
            && lhs.icon == rhs.icon
    }


}

extension PluginDirectoryEntry: Decodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case slug
        case version
        case lastUpdated = "last_updated"
        case icons
        case author
        case rating

        case banners

        case sections
    }

    private enum BannersKeys: String, CodingKey {
        case high
        case low
    }

    private enum SectionKeys: String, CodingKey {
        case description
        case installation
        case faq
        case changelog
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        slug = try container.decode(String.self, forKey: .slug)
        version = try? container.decode(String.self, forKey: .version)
        lastUpdated = try? container.decode(Date.self, forKey: .lastUpdated)
        rating = try container.decode(Int.self, forKey: .rating)

        let icons = try? container.decodeIfPresent([String: String].self, forKey: .icons)
        icon = icons??["2x"].flatMap(URL.init(string:))

        // If there's no hi-res version of the banner, the API returns `high: false`, instead of something more logical,
        // like an empty string or `null`, hence the dance below.
        let banners = try? container.nestedContainer(keyedBy: BannersKeys.self, forKey: .banners)

        if let highRes = try? banners?.decodeIfPresent(String.self, forKey: .high) {
            banner = highRes.flatMap(URL.init(string:))
        } else if let lowRes = try? banners?.decodeIfPresent(String.self, forKey: .low) {
            banner = lowRes.flatMap(URL.init(string:))
        } else {
            banner = nil
        }

        let extractedAuthor = extractAuthor(try container.decode(String.self, forKey: .author))

        author = extractedAuthor.name
        authorURL = extractedAuthor.link

        let sections = try? container.nestedContainer(keyedBy: SectionKeys.self, forKey: .sections)

        descriptionHTML = try trimTags(sections?.decodeIfPresent(String.self, forKey: .description))
        installationHTML = try trimTags(sections?.decodeIfPresent(String.self, forKey: .installation))
        faqHTML = try trimTags(sections?.decodeIfPresent(String.self, forKey: .faq))

        let changelog = try sections?.decodeIfPresent(String.self, forKey: .changelog)
        changelogHTML = trimTags(trimChangelog(changelog))
    }

    internal init(responseObject: [String: AnyObject]) throws {
        // Data returned by the featured plugins API endpoint is almost exactly in the same format
        // as the data from the Plugin Directory, with few fields missing (updateDate, version, etc).
        // In order to avoid duplicating almost identical entites, we provide a special initializer
        // that `nil`s out those fields.

        guard let name = responseObject["name"] as? String,
            let slug = responseObject["slug"] as? String,
            let authorString = responseObject["author"] as? String,
            let rating = responseObject["rating"] as? Int else {
                throw PluginServiceRemote.ResponseError.decodingFailure
        }

        self.name = name
        self.slug = slug
        self.rating = rating

        let author = extractAuthor(authorString)
        self.author = author.name

        if let icon = (responseObject["icons"]?["2x"] as? String).flatMap({ URL(string: $0) }) {
            self.icon = icon
        } else {
            self.icon = (responseObject["icons"]?["1x"] as? String).flatMap { URL(string: $0) }
        }

        self.version = nil
        self.lastUpdated = nil
        self.banner = nil
        self.authorURL = nil
        self.descriptionHTML = nil
        self.installationHTML = nil
        self.faqHTML = nil
        self.changelogHTML = nil
    }
}

// Since the WPOrg API returns `author` as a HTML string (or freeform text), we need to get ugly and parse out the important bits out of it ourselves.
typealias Author = (name: String, link: URL?)
private func extractAuthor(_ string: String) -> Author {
    guard let attributedString = extractHTMLText(string) else {
        return (name: string, link: nil)
    }

    let authorName = attributedString.string
    let authorURL = attributedString.attributes(at: 0, effectiveRange: nil)[.link] as? URL
    return (authorName, authorURL)
}

private func extractHTMLText(_ text: String?) -> NSAttributedString? {
    guard Thread.isMainThread,
        let data = text?.data(using: .utf16),
        let attributedString = try? NSAttributedString(data: data, options: [.documentType : NSAttributedString.DocumentType.html], documentAttributes: nil) else {
            return nil
    }

    return attributedString
}

private func trimTags(_ htmlString: String?) -> String? {
    // Because the HTML we get from backend can contain literally anything, we need to set some limits as to what we won't even try to parse.
    let tagsToRemove = ["script", "iframe"]

    guard var html = htmlString else { return nil }

    for tag in tagsToRemove {
        let openingTag = "<\(tag)"
        let closingTag  = "/\(tag)>"

        if let openingRange = html.range(of: openingTag),
           let closingRange = html.range(of: closingTag) {

            let rangeToRemove = openingRange.lowerBound..<closingRange.upperBound
            html.removeSubrange(rangeToRemove)
        }
    }

    return html
}

private func trimChangelog(_ changelog: String?) -> String? {
    // The changelog that some plugins return is HUGE — Gutenberg as of 2.0 for example returns over 50KiB of text and 1000s of lines,
    // Akismet has changelog going back to 2009, etc — there isn't any backend-enforced limit, but thankfully there is backend-enforced structure.
    // Showing more than last versions rel-notes seems somewhat poinless (and unlike how, e.g. App Store works), so we trim it to just the
    // latest version here. If the user wants to see the whole thing, they can open the plugin's page in WPOrg directory in a browser.
    guard let log = changelog else { return nil }

    guard let firstOccurence = log.range(of: "<h4>") else {
        // Each "version" in the changelog is delineated by the version number wrapped in `<h4>`.
        // If the payload doesn't follow the format we're expecting, let's not trim it and return what we received.
        return log
    }

    let rangeAfterFirstOccurence = firstOccurence.upperBound ..< log.endIndex
    guard let secondOccurence = log.range(of: "<h4>", range: rangeAfterFirstOccurence) else {
        // Same as above. If the data doesn't the format we're expecting, bail.
        return log
    }

    return String(log[log.startIndex ..< secondOccurence.lowerBound])
}
