import CoreSpotlight
import MobileCoreServices

@objc enum SearchItemType: Int {
    case abstractPost
    case readerPost
    case none

    init(index: String) {
        switch index.lowercased().trim() {
        case "abstractpost":
            self = .abstractPost
        case "readerpost":
            self = .readerPost
        default:
            self = .none
        }
    }

    func stringValue() -> String {
        switch self {
        case .abstractPost:
            return "abstractPost"
        case .readerPost:
            return "readerPost"
        case .none:
            return "none"
        }
    }
}

// MARK: - SearchableItemConvertable

@objc protocol SearchableItemConvertable {
    /// Identifies the item type this is
    ///
    var searchItemType: SearchItemType {get}

    /// Identifies if this item should be indexed
    ///
    var isSearchable: Bool {get}

    /// The value that uniquely identifies the searchable item
    ///
    var searchIdentifier: String? {get}

    /// The value that identifies what class this searchable item belongs to (e.g. SiteID, etc)
    ///
    var searchDomain: String? {get}

    /// Item title to be displayed in spotlight search
    ///
    var searchTitle: String? {get}

    /// Item description
    ///
    var searchDescription: String? {get}

    // MARK: Optional Vars

    /// An optional array of keywords associated with the item
    ///
    @objc optional var searchKeywords: [String]? {get}

    /// *Local* URL to image that should be displayed in spotlight search
    ///
    @objc optional var searchLocalImageURL: URL? {get}
}

extension SearchableItemConvertable {
    internal var uniqueIdentifier: String? {
        guard let searchDomain = searchDomain, let searchIdentifier = searchIdentifier else {
            return nil
        }
        return SearchIdentifierGenerator.composeUniqueIdentifier(itemType: searchItemType, domain: searchDomain, identifier: searchIdentifier)
    }

    internal func indexableItem() -> CSSearchableItem? {
        guard isSearchable == true,
            let uniqueIdentifier = uniqueIdentifier,
            let searchTitle = searchTitle,
            let searchDescription = searchDescription else {
            return nil
        }

        let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        searchableItemAttributeSet.title = searchTitle
        searchableItemAttributeSet.contentDescription = searchDescription

        if let keywords = searchKeywords {
            searchableItemAttributeSet.keywords = keywords
        }

        if let imgURL = searchLocalImageURL {
            searchableItemAttributeSet.thumbnailURL = imgURL
        }

        return CSSearchableItem(uniqueIdentifier: uniqueIdentifier,
                                domainIdentifier: searchDomain,
                                attributeSet: searchableItemAttributeSet)
    }
}
