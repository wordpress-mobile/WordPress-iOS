import Foundation
import WordPressAPI
import WordPressAPIInternal

struct SiteTaxonomy {
    let details: TaxonomyTypeDetailsWithEditContext

    var slug: String {
        details.slug
    }

    var localizedName: String {
        (details.labels[.name] ?? nil) ?? details.name
    }

    var endpoint: TermEndpointType {
        .custom(details.restBase)
    }
}
