import WordPressAPI
import WordPressAPIInternal

extension PostTypeDetailsWithEditContext {
    static func fixture(slug: String, name: String) -> PostTypeDetailsWithEditContext {
        PostTypeDetailsWithEditContext(
            capabilities: [:],
            description: "",
            hierarchical: false,
            viewable: true,
            labels: .empty,
            name: name,
            slug: slug,
            supports: PostTypeSupportsMap(map: [
                .title: .bool(true),
                .editor: .bool(true)
            ]),
            hasArchive: .bool(false),
            taxonomies: [],
            restBase: slug,
            restNamespace: "wp/v2",
            visibility: PostTypeVisibility(showInNavMenus: true, showUi: true),
            icon: nil
        )
    }
}

private extension PostTypeLabels {
    static let empty = PostTypeLabels(
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
