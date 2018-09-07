
class FormattableUserContent: NotificationTextContent {
    override var kind: FormattableContentKind {
        return .user
    }

    var metaLinksHome: URL? {
        guard let rawLink = metaLinks?[Constants.MetaKeys.Home] as? String else {
            return nil
        }

        return URL(string: rawLink)
    }

    public var metaTitlesHome: String? {
        return metaTitles?[Constants.MetaKeys.Home] as? String
    }

    private var metaLinks: [String: AnyObject]? {
        return meta?[Constants.MetaKeys.Links] as? [String: AnyObject]
    }

    private var metaTitles: [String: AnyObject]? {
        return meta?[Constants.MetaKeys.Titles] as? [String: AnyObject]
    }

    private var metaIds: [String: AnyObject]? {
        return meta?[Constants.MetaKeys.Ids] as? [String: AnyObject]
    }

    var notificationID: String? {
        return parent.notificationIdentifier
    }

    var metaSiteID: NSNumber? {
        return metaIds?[Constants.MetaKeys.Site] as? NSNumber
    }
}

extension FormattableUserContent: Equatable {
    static func == (lhs: FormattableUserContent, rhs: FormattableUserContent) -> Bool {
        return lhs.isEqual(to: rhs) &&
            lhs.parent.notificationIdentifier == rhs.parent.notificationIdentifier
    }

    private func isEqual(to other: FormattableUserContent) -> Bool {
        return text == other.text &&
            ranges.count == other.ranges.count
    }
}

private enum Constants {
    fileprivate enum MetaKeys {
        static let Ids          = "ids"
        static let Site         = "site"
        static let Titles       = "titles"
        static let Home         = "home"
        static let Links        = "links"
    }
}
