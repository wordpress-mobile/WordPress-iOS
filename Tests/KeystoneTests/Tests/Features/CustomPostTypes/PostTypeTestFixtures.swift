import WordPressAPI
import WordPressAPIInternal

func makeTestPostType(
    slug: String = "test_post_type",
    name: String = "Test Post Type",
    restBase: String? = nil,
    viewable: Bool = true,
    showUi: Bool = true,
    // `supports(feature:)` checks key presence, as the REST API omits unsupported features.
    supports: [PostTypeSupports: JsonValue] = [.title: .bool(true), .editor: .bool(true)]
) -> PostTypeDetailsWithEditContext {
    PostTypeDetailsWithEditContext(
        capabilities: [:],
        description: "",
        hierarchical: false,
        viewable: viewable,
        labels: makeTestPostTypeLabels(),
        name: name,
        slug: slug,
        supports: PostTypeSupportsMap(map: supports),
        hasArchive: .bool(false),
        taxonomies: [],
        restBase: restBase ?? slug,
        restNamespace: "wp/v2",
        visibility: PostTypeVisibility(showInNavMenus: true, showUi: showUi),
        icon: nil
    )
}

private func makeTestPostTypeLabels() -> PostTypeLabels {
    PostTypeLabels(
        name: "",
        singularName: "",
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
    )
}
