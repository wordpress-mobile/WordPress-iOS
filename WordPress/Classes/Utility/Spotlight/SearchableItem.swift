import CoreSpotlight
import MobileCoreServices

// MARK: - SearchableItemConvertable

@objc protocol SearchableItemConvertable {

    /// The value that uniquely identifies the searchable item
    ///
    var searchIdentifier: String {get}

    /// The value that identifies what class this searchable item belongs to (e.g. SiteID, etc)
    ///
    var searchDomain: String {get}

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

    /// Optional item thumbnail to be displayed in spotlight search
    ///
    @objc optional var searchImage: UIImage? {get}
}

extension SearchableItemConvertable {
    var thumbnailImage: UIImage? { return nil }

    internal var uniqueIdentifier: String {
        return SearchIdentifierGenerator.composeUniqueIdentifier(domain: searchDomain, identifier: searchIdentifier)
    }

    internal func indexableItem() -> CSSearchableItem {
        let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        searchableItemAttributeSet.title = searchTitle
        searchableItemAttributeSet.contentDescription = searchDescription

        if let keywords = searchKeywords {
            searchableItemAttributeSet.keywords = keywords
        }

        if let img = searchImage {
            searchableItemAttributeSet.thumbnailData = UIImageJPEGRepresentation(img!, 0.1)
        }

        return CSSearchableItem(uniqueIdentifier: uniqueIdentifier,
                                domainIdentifier: searchDomain,
                                attributeSet: searchableItemAttributeSet)
    }
}

// MARK: - SearchableItemRetrievable

protocol SearchableItemRetrievable: SearchableItemConvertable {
    func retrieveItem(with identifier: String) throws -> Self?
}
