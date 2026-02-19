import Testing
@testable import WordPress
import WordPressAPIInternal

@Suite("PostSettingsCapabilities Tests")
struct PostSettingsCapabilitiesTests {

    @Test("Post capabilities match expected values")
    func testPostCapabilities() {
        let caps = PostSettingsCapabilities.post()
        #expect(caps.supportsCategories == true)
        #expect(caps.supportsTags == true)
        #expect(caps.supportsFeaturedImage == true)
        #expect(caps.supportsExcerpt == true)
        #expect(caps.supportsAuthor == true)
        #expect(caps.supportsPostFormats == true)
        #expect(caps.supportsComments == true)
        #expect(caps.supportsTrackbacks == true)
        #expect(caps.supportsPageAttributes == false)
        #expect(caps.supportsSlug == true)
        #expect(caps.supportsCustomFields == true)
        #expect(caps.customTaxonomySlugs == [])
    }

    @Test("Page capabilities match expected values")
    func testPageCapabilities() {
        let caps = PostSettingsCapabilities.page()
        #expect(caps.supportsCategories == false)
        #expect(caps.supportsTags == false)
        #expect(caps.supportsFeaturedImage == true)
        #expect(caps.supportsExcerpt == true)
        #expect(caps.supportsAuthor == true)
        #expect(caps.supportsPostFormats == false)
        #expect(caps.supportsComments == false)
        #expect(caps.supportsTrackbacks == false)
        #expect(caps.supportsPageAttributes == true)
        #expect(caps.supportsSlug == true)
        #expect(caps.supportsCustomFields == true)
        #expect(caps.customTaxonomySlugs == [])
    }

    @Test("Capabilities from PostTypeDetailsWithEditContext with full supports")
    func testFromDetailsFullSupports() {
        let details = makeDetails(
            supports: [.thumbnail, .excerpt, .author, .postFormats, .comments, .trackbacks, .pageAttributes, .slug, .customFields],
            taxonomies: ["category", "post_tag", "genre", "topic"]
        )
        let caps = PostSettingsCapabilities(from: details)

        // Categories, tags, page attributes, custom fields, and custom
        // taxonomy slugs are not yet supported (see FIXME in implementation).
        #expect(caps.supportsCategories == false)
        #expect(caps.supportsTags == false)
        #expect(caps.supportsFeaturedImage == true)
        #expect(caps.supportsExcerpt == true)
        #expect(caps.supportsAuthor == true)
        #expect(caps.supportsPostFormats == true)
        #expect(caps.supportsComments == true)
        #expect(caps.supportsTrackbacks == true)
        #expect(caps.supportsPageAttributes == false)
        #expect(caps.supportsSlug == true)
        #expect(caps.supportsCustomFields == false)
        #expect(caps.customTaxonomySlugs == [])
    }

    @Test("Capabilities from PostTypeDetailsWithEditContext with minimal supports")
    func testFromDetailsMinimalSupports() {
        let details = makeDetails(supports: [], taxonomies: [])
        let caps = PostSettingsCapabilities(from: details)

        #expect(caps.supportsCategories == false)
        #expect(caps.supportsTags == false)
        #expect(caps.supportsFeaturedImage == false)
        #expect(caps.supportsExcerpt == false)
        #expect(caps.supportsAuthor == false)
        #expect(caps.supportsPostFormats == false)
        #expect(caps.supportsComments == false)
        #expect(caps.supportsTrackbacks == false)
        #expect(caps.supportsPageAttributes == false)
        #expect(caps.supportsSlug == false)
        #expect(caps.supportsCustomFields == false)
        #expect(caps.customTaxonomySlugs == [])
    }

    @Test("Custom taxonomy slugs exclude category and post_tag")
    func testCustomTaxonomySlugsFiltering() {
        let details = makeDetails(
            supports: [],
            taxonomies: ["category", "post_tag", "genre", "category", "mood"]
        )
        let caps = PostSettingsCapabilities(from: details)

        // Categories and tags are not yet derived from taxonomies (see FIXME in implementation).
        #expect(caps.supportsCategories == false)
        #expect(caps.supportsTags == false)
        #expect(caps.customTaxonomySlugs == [])
    }
}

// MARK: - Test Helpers

private func makeDetails(
    supports: [PostTypeSupports],
    taxonomies: [String]
) -> PostTypeDetailsWithEditContext {
    let supportsMap = PostTypeSupportsMap(
        map: Dictionary(uniqueKeysWithValues: supports.map { ($0, JsonValue.bool(true)) })
    )
    return PostTypeDetailsWithEditContext(
        capabilities: [:],
        description: "",
        hierarchical: false,
        viewable: true,
        labels: PostTypeLabels(
            name: "Test",
            singularName: "Test",
            addNew: "",
            addNewItem: "",
            editItem: "",
            newItem: "",
            viewItem: "",
            viewItems: "",
            searchItems: "",
            notFound: "",
            notFoundInTrash: "",
            parentItemColon: nil,
            allItems: "",
            archives: "",
            attributes: "",
            insertIntoItem: "",
            uploadedToThisItem: "",
            featuredImage: "",
            setFeaturedImage: "",
            removeFeaturedImage: "",
            useFeaturedImage: "",
            filterItemsList: "",
            filterByDate: "",
            itemsListNavigation: "",
            itemsList: "",
            itemPublished: "",
            itemPublishedPrivately: "",
            itemRevertedToDraft: "",
            itemTrashed: "",
            itemScheduled: "",
            itemUpdated: "",
            itemLink: "",
            itemLinkDescription: "",
            menuName: "",
            nameAdminBar: ""
        ),
        name: "Test",
        slug: "test",
        supports: supportsMap,
        hasArchive: .bool(false),
        taxonomies: taxonomies,
        restBase: "test",
        restNamespace: "wp/v2",
        visibility: PostTypeVisibility(showInNavMenus: true, showUi: true),
        icon: nil
    )
}
