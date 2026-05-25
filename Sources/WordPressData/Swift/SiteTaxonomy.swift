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

    public var restBase: String

    init(slug: String, name: String, restBase: String, supportedPostTypes: [String] = []) {
        self.slug = slug
        self.name = name
        self.restBase = restBase
        self.labels = .init()
        self.supportedPostTypes = supportedPostTypes
    }

    public init(details: TaxonomyTypeDetailsWithEditContext) {
        self.slug = details.slug
        self.name = details.name
        self.restBase = details.restBase
        self.labels = LocalizedLabels(
            name: details.labels[.name],
            newItemName: details.labels[.newItemName],
            addNewItem: details.labels[.addNewItem],
            nameFieldDescription: details.labels[.nameFieldDescription],
            descFieldDescription: details.labels[.descFieldDescription],
            noTerms: details.labels[.noTerms],
            searchItems: details.labels[.searchItems]
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
