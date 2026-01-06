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

    var localizedTaxonomyName: String {
        taxonomy?.localizedName ?? Strings.tags
    }

    var isBrowseMode: Bool {
        if case .browse = mode {
            return true
        }
        return false
    }

    convenience init(blog: Blog, selectedTags: String? = nil, mode: TagsViewMode) {
        self.init(taxonomy: nil, service: TagsService(blog: blog), selectedTerms: selectedTags, mode: mode)
    }

    convenience init(blog: Blog, client: WordPressClient, taxonomy: SiteTaxonomy, selectedTerms: String? = nil, mode: TagsViewMode) {
        self.init(taxonomy: taxonomy, service: AnyTermService(client: client, endpoint: taxonomy.endpoint), selectedTerms: selectedTerms, mode: mode)
    }

    init(taxonomy: SiteTaxonomy?, service: TaxonomyServiceProtocol, selectedTerms: String? = nil, mode: TagsViewMode) {
        self.taxonomy = taxonomy
        self.tagsService = service
        self.mode = mode
        self.labels = taxonomy.flatMap(TaxonomyLocalizedLabels.from(taxonomy:)) ?? TaxonomyLocalizedLabels.tag
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
            selectedTags.removeAll { $0.lowercased() == lowercasedTagName }
        } else {
            selectedTagsSet.insert(lowercasedTagName)
            selectedTags.append(tagName)
        }
        searchText = ""
    }

    /// The return value `Task` instance is for creating the new tag in the background.
    @discardableResult
    func addNewTag(named name: String) -> Task<Void, Never>? {
        let lowercasedName = name.lowercased()
        guard !selectedTagsSet.contains(lowercasedName) else { return nil }

        selectedTagsSet.insert(lowercasedName)
        selectedTags.append(name)

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

                // The original input `name` was used as a temporary tag before sending the API request.
                // Replace it with the actual tag returned by the API.
                if newTag.name != name, let index = selectedTags.firstIndex(of: name) {
                    selectedTagsSet.remove(lowercasedName)
                    selectedTagsSet.insert(newTag.name.lowercased())
                    selectedTags[index] = newTag.name
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
