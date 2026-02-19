import WordPressAPIInternal

struct PostSettingsCapabilities {
    var supportsCategories: Bool
    var supportsTags: Bool
    var supportsFeaturedImage: Bool
    var supportsExcerpt: Bool
    var supportsAuthor: Bool
    var supportsPostFormats: Bool
    var supportsComments: Bool
    var supportsTrackbacks: Bool
    var supportsPageAttributes: Bool
    var supportsSlug: Bool
    var supportsCustomFields: Bool
    var customTaxonomySlugs: [String]
}

// The 'post' and 'page' capabilities are hard-coded for now. Later on, we can keep only the
// initializer that uses `PostTypeDetailsWithEditContext`.
extension PostSettingsCapabilities {
    /// Capabilities for the built-in "post" type.
    static func post() -> PostSettingsCapabilities {
        PostSettingsCapabilities(
            supportsCategories: true,
            supportsTags: true,
            supportsFeaturedImage: true,
            supportsExcerpt: true,
            supportsAuthor: true,
            supportsPostFormats: true,
            supportsComments: true,
            supportsTrackbacks: true,
            supportsPageAttributes: false,
            supportsSlug: true,
            supportsCustomFields: true,
            customTaxonomySlugs: []
        )
    }

    /// Capabilities for the built-in "page" type.
    ///
    /// Note: Pages support comments at the platform level, but the app's
    /// Post Settings screen has never shown discussion settings for pages.
    static func page() -> PostSettingsCapabilities {
        PostSettingsCapabilities(
            supportsCategories: false,
            supportsTags: false,
            supportsFeaturedImage: true,
            supportsExcerpt: true,
            supportsAuthor: true,
            supportsPostFormats: false,
            supportsComments: false,
            supportsTrackbacks: false,
            supportsPageAttributes: true,
            supportsSlug: true,
            supportsCustomFields: true,
            customTaxonomySlugs: []
        )
    }

    /// Capabilities derived from REST API post type details.
    init(from details: PostTypeDetailsWithEditContext) {
        // FIXME: Add taxonomy support
        supportsCategories = false // details.taxonomies.contains("category")
        supportsTags = false // details.taxonomies.contains("post_tag")
        supportsFeaturedImage = details.supports.supports(feature: .thumbnail)
        supportsExcerpt = details.supports.supports(feature: .excerpt)
        supportsAuthor = details.supports.supports(feature: .author)
        supportsPostFormats = details.supports.supports(feature: .postFormats)
        supportsComments = details.supports.supports(feature: .comments)
        supportsTrackbacks = details.supports.supports(feature: .trackbacks)
        supportsPageAttributes = false // details.supports.supports(feature: .pageAttributes)
        supportsSlug = details.supports.supports(feature: .slug)
        supportsCustomFields = false // details.supports.supports(feature: .customFields)
        customTaxonomySlugs = [] // details.taxonomies.filter { $0 != "category" && $0 != "post_tag" }
    }
}
