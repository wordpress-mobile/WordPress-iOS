import Foundation
import WordPressAPI
import WordPressAPIInternal

public struct SiteTaxonomy: Codable {
    public struct LocalizedLabels: Codable {
        public var name: String?
        public var newItemName: String?
        public var addNewItem: String?
        public var nameFieldDescription: String?
        public var descFieldDescription: String?
        public var noTerms: String?
        public var searchItems: String?
    }

    public var slug: String
    public var name: String
    public var labels: LocalizedLabels
    public var supportedPostTypes: [String] = []

    var restBase: String

    public init(details: TaxonomyTypeDetailsWithEditContext) {
        self.slug = details.slug
        self.name = details.name
        self.restBase = details.restBase
        self.labels = LocalizedLabels(
            name: details.labels[.name] ?? nil,
            newItemName: details.labels[.newItemName] ?? nil,
            addNewItem: details.labels[.addNewItem] ?? nil,
            nameFieldDescription: details.labels[.nameFieldDescription] ?? nil,
            descFieldDescription: details.labels[.descFieldDescription] ?? nil,
            noTerms: details.labels[.noTerms] ?? nil,
            searchItems: details.labels[.searchItems] ?? nil
        )
        self.supportedPostTypes = details.types
    }

    public var localizedName: String {
        labels.name ?? name
    }

    public var endpoint: TermEndpointType {
        .custom(restBase)
    }
}
