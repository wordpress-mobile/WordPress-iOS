import Foundation
import WordPressKit
import WordPressData
import WordPressUI
import WordPressShared
import WordPressAPI
import WordPressCore

typealias TagsPaginatedResponse = DataViewPaginatedResponse<AnyTermWithViewContext, Int>

enum TagsViewMode {
    case selection(onSelectedTagsChanged: (([TagsViewModel.SelectedTerm]) -> Void)?)
    case browse
}

@MainActor
class TagsViewModel: ObservableObject {
    struct SelectedTerm: Hashable {
        let id: Int
        var name: String

        /// Tags with `id == 0` have been entered by the user but not yet confirmed
        /// by the server (search or create is in flight).
        var isPending: Bool { id == 0 }
    }
    @Published var searchText = ""
    @Published private(set) var response: TagsPaginatedResponse?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var selectedTags: [SelectedTerm] {
        didSet {
            if case .selection(let onSelectedTagsChanged) = mode {
                onSelectedTagsChanged?(selectedTags.filter { !$0.isPending })
            }
        }
    }
    private var selectedTagsSet: Set<String> = []

    let tagsService: TaxonomyServiceProtocol
    let mode: TagsViewMode
    let labels: TaxonomyLocalizedLabels
    let taxonomy: SiteTaxonomy?

    var localizedTaxonomyName: String {
        taxonomy?.localizedName ?? Strings.tags
    }

    var isBrowseMode: Bool {
        if case .browse = mode {
            return true
        }
        return false
    }

    convenience init(blog: Blog, selectedTags: [SelectedTerm] = [], mode: TagsViewMode) {
        self.init(taxonomy: nil, service: TagsService(blog: blog), selectedTerms: selectedTags, mode: mode)
    }

    convenience init(blog: Blog, client: WordPressClient, taxonomy: SiteTaxonomy, selectedTerms: [SelectedTerm] = [], mode: TagsViewMode) {
        self.init(taxonomy: taxonomy, service: AnyTermService(client: client, endpoint: taxonomy.endpoint), selectedTerms: selectedTerms, mode: mode)
    }

    init(taxonomy: SiteTaxonomy?, service: TaxonomyServiceProtocol, selectedTerms: [SelectedTerm] = [], mode: TagsViewMode) {
        self.taxonomy = taxonomy
        self.tagsService = service
        self.mode = mode
        self.labels = taxonomy.flatMap(TaxonomyLocalizedLabels.from(taxonomy:)) ?? TaxonomyLocalizedLabels.tag
        self.selectedTags = selectedTerms
        self.selectedTagsSet = Set(selectedTerms.map { $0.name.lowercased() })
    }

    func onAppear() {
        guard response == nil else { return }
        Task {
            async let _ = await loadInitialTags()
            async let _ = await resolvePendingSelectedTerms()
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
                    recentlyUsed: !self.isBrowseMode
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
            selectedTags.removeAll { $0.name.lowercased() == lowercasedTagName }
        } else {
            selectedTagsSet.insert(lowercasedTagName)
            selectedTags.append(SelectedTerm(id: Int(term.id), name: term.name))
        }
        searchText = ""
    }

    /// The return value `Task` instance is for creating the new tag in the background.
    @discardableResult
    func addNewTag(named name: String) -> Task<Void, Never>? {
        let lowercasedName = name.lowercased()
        guard !selectedTagsSet.contains(lowercasedName) else { return nil }

        selectedTagsSet.insert(lowercasedName)
        selectedTags.append(SelectedTerm(id: 0, name: name))

        // Create a new tag in the background, which is consistent with the web editor.
        return Task {
            do {
                let newTag: AnyTermWithViewContext
                if let existing = try await tagsService.searchTags(with: name)
                    .first(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) {
                    newTag = existing
                } else {
                    newTag = try await tagsService.createTag(name: name, description: "")
                }

                // Replace the pending item with the confirmed one from the server.
                if let index = selectedTags.firstIndex(where: { $0.name == name }) {
                    selectedTagsSet.remove(lowercasedName)
                    selectedTagsSet.insert(newTag.name.lowercased())
                    selectedTags[index] = SelectedTerm(id: Int(newTag.id), name: newTag.name)
                }
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
        selectedTags.removeAll { $0.name.lowercased() == lowercasedTagName }
    }

    /// Resolves selected tags that have `id == 0` by searching for them on the server.
    ///
    /// Unlike `addNewTag`, this only searches — it does not create missing tags,
    /// because these are already-selected tags that most likely exist on the server.
    private func resolvePendingSelectedTerms() async {
        let pendingNames = selectedTags.filter { $0.isPending }.map(\.name)
        guard !pendingNames.isEmpty else { return }

        let resolved = await tagsService.resolveTerms(named: pendingNames)

        for (name, existing) in resolved {
            if let index = selectedTags.firstIndex(where: { $0.name == name }) {
                selectedTagsSet.remove(name.lowercased())
                selectedTagsSet.insert(existing.name.lowercased())
                selectedTags[index] = SelectedTerm(id: Int(existing.id), name: existing.name)
            }
        }
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
            empty: taxonomy.labels.noTerms
                ?? String.localizedStringWithFormat(Strings.defaultNoTermsFormat, taxonomy.name),
            emptyDescription: String.localizedStringWithFormat(Strings.defaultEmptyDescriptionFormat, taxonomy.name),
            searchPlaceholder: taxonomy.labels.searchItems
                ?? String.localizedStringWithFormat(Strings.defaultSearchFormat, taxonomy.name)
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
    static let tags = NSLocalizedString(
        "Tags",
        value: "Tags",
        comment: "Post tags."
    )

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
