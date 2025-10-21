import Foundation
import WordPressKit
import WordPressData
import WordPressUI
import WordPressShared
import WordPressAPI
import WordPressCore

typealias TagsPaginatedResponse = DataViewPaginatedResponse<AnyTermWithViewContext, Int>

enum TagsViewMode {
    case selection(onSelectedTagsChanged: ((String) -> Void)?)
    case browse
}

@MainActor
class TagsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var response: TagsPaginatedResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var selectedTags: [String] {
        didSet {
            if case .selection(let onSelectedTagsChanged) = mode {
                onSelectedTagsChanged?(selectedTags.joined(separator: ", "))
            }
        }
    }
    private var selectedTagsSet: Set<String> = []

    let tagsService: TaxonomyServiceProtocol
    let mode: TagsViewMode
    let labels: TaxonomyLocalizedLabels
    let taxonomy: SiteTaxonomy?

    var isBrowseMode: Bool {
        if case .browse = mode {
            return true
        }
        return false
    }

    init(blog: Blog, selectedTags: String? = nil, mode: TagsViewMode) {
        self.taxonomy = nil
        self.tagsService = TagsService(blog: blog)
        self.mode = mode
        self.labels = TaxonomyLocalizedLabels.tag
        self.selectedTags = AbstractPost.makeTags(from: selectedTags ?? "")
        self.selectedTagsSet = Set(self.selectedTags.map { $0.lowercased() })
    }

    init(blog: Blog, api: WordPressAPI, taxonomy: SiteTaxonomy, selectedTerms: String? = nil, mode: TagsViewMode) {
        self.taxonomy = taxonomy
        self.tagsService = AnyTermService(api: api, endpoint: taxonomy.endpoint)
        self.mode = mode
        self.labels = TaxonomyLocalizedLabels.from(taxonomy: taxonomy)
        self.selectedTags = AbstractPost.makeTags(from: selectedTerms ?? "")
        self.selectedTagsSet = Set(self.selectedTags.map { $0.lowercased() })
    }

    func onAppear() {
        guard response == nil else { return }
        Task {
            await loadInitialTags()
        }
    }

    func refresh() async {
        response = nil
        error = nil
        await loadInitialTags()
    }

    private func loadInitialTags() async {
        isLoading = true
        defer { isLoading = false}

        error = nil

        do {
            let paginatedResponse = try await TagsPaginatedResponse { [weak self] pageIndex in
                guard let self else {
                    throw TagsServiceError.noRemoteService
                }

                let page = pageIndex ?? 0
                let remoteTags = try await self.tagsService.getTags(
                    page: page,
                    recentlyUsed: self.isBrowseMode
                )

                let hasMore = remoteTags.count == 100
                let nextPage = hasMore ? page + 1 : nil

                return TagsPaginatedResponse.Page(
                    items: remoteTags,
                    total: nil,
                    hasMore: hasMore,
                    nextPage: nextPage
                )
            }

            self.response = paginatedResponse
        } catch {
            self.error = error
        }
    }

    var isLocalSearchEnabled: Bool {
        guard let response else { return false }
        return !response.hasMore
    }

    func search() async throws -> TagsPaginatedResponse {
        if let response, !response.hasMore {
            let results = await StringRankedSearch(searchTerm: searchText)
                .parallelSearch(in: response.items, input: \.name)
            return try await TagsPaginatedResponse { _ in
                TagsPaginatedResponse.Page(items: results, total: results.count, hasMore: false, nextPage: nil)
            }
        }

        let remoteTags = try await tagsService.searchTags(with: searchText)

        return try await TagsPaginatedResponse { _ in
            return TagsPaginatedResponse.Page(
                items: remoteTags,
                total: remoteTags.count,
                hasMore: false,
                nextPage: nil
            )
        }
    }

    func toggleSelection(for term: AnyTermWithViewContext) {
        let tagName = term.name
        let lowercasedTagName = tagName.lowercased()
        if selectedTagsSet.contains(lowercasedTagName) {
            selectedTagsSet.remove(lowercasedTagName)
            selectedTags.removeAll { $0.lowercased() == lowercasedTagName }
        } else {
            selectedTagsSet.insert(lowercasedTagName)
            selectedTags.append(tagName)
        }
        searchText = ""
    }

    func addNewTag(named name: String) {
        let lowercasedName = name.lowercased()
        guard !selectedTagsSet.contains(lowercasedName) else { return }

        selectedTagsSet.insert(lowercasedName)
        selectedTags.append(name)

        // Create a new tag in the background, which is consistent with the web editor.
        Task {
            do {
                _ = try await tagsService.createTag(name: name, description: "")
            } catch {
                removeSelectedTag(name)
            }
        }
    }

    func isSelected(_ term: AnyTermWithViewContext) -> Bool {
        return selectedTagsSet.contains(term.name.lowercased())
    }

    func isNotSelected(_ term: AnyTermWithViewContext) -> Bool {
        !isSelected(term)
    }

    func removeSelectedTag(_ tagName: String) {
        let lowercasedTagName = tagName.lowercased()
        selectedTagsSet.remove(lowercasedTagName)
        selectedTags.removeAll { $0.lowercased() == lowercasedTagName }
    }
}

extension Foundation.Notification.Name {
    @MainActor
    static let tagDeleted = Foundation.Notification.Name("tagDeleted")
    @MainActor
    static let tagCreated = Foundation.Notification.Name("tagCreated")
    @MainActor
    static let tagUpdated = Foundation.Notification.Name("tagUpdated")
}

struct TagNotificationUserInfoKeys {
    static let tagID = "tagID"
    static let tag = "tag"
}

struct TaxonomyLocalizedLabels {
    var name: String
    var empty: String
    var emptyDescription: String
    var searchPlaceholder: String

    static func from(taxonomy: SiteTaxonomy) -> Self {
        Self(
            name: taxonomy.localizedName,
            empty: (taxonomy.details.labels[.noTerms] ?? nil)
                ?? String.localizedStringWithFormat(Strings.defaultNoTermsFormat, taxonomy.details.name),
            emptyDescription: String.localizedStringWithFormat(Strings.defaultEmptyDescriptionFormat, taxonomy.details.name),
            searchPlaceholder: (taxonomy.details.labels[.searchItems] ?? nil)
                ?? String.localizedStringWithFormat(Strings.defaultSearchFormat, taxonomy.details.name)
        )
    }

    static var tag: Self {
        Self(
            name: NSLocalizedString(
                "tags.title",
                value: "Tags",
                comment: "Title for the tags screen"
            ),
            empty: NSLocalizedString(
                "tags.empty.title",
                value: "No Tags",
                comment: "Title for empty state when there are no tags"
            ),
            emptyDescription: NSLocalizedString(
                "tags.empty.description",
                value: "Tags help organize your content and make it easier for readers to find related posts.",
                comment: "Description for empty state when there are no tags"
            ),
            searchPlaceholder: NSLocalizedString(
                "tags.search.placeholder",
                value: "Search tags",
                comment: "Placeholder text for the tag search field"
            )
        )
    }
}

private enum Strings {
    static let defaultNoTermsFormat = NSLocalizedString(
        "localizedLabels.defaultNoTerms.format",
        value: "No %1$@",
        comment: "Default empty state message format when there are no terms. %1$@ is the taxonomy name."
    )
    static let defaultSearchFormat = NSLocalizedString(
        "localizedLabels.defaultSearch.format",
        value: "Search %1$@",
        comment: "Default search placeholder format. %1$@ is the taxonomy name."
    )
    static let defaultEmptyDescriptionFormat = NSLocalizedString(
        "tags.empty.description",
        value: "%1$@ help organize your content and make it easier for readers to find related posts.",
        comment: "Description for empty state when there are no tags. %1$@ is the taxonomy name."
    )
}
