import Foundation
import WordPressKit
import WordPressData
import WordPressUI
import WordPressShared

typealias TagsPaginatedResponse = DataViewPaginatedResponse<RemotePostTag, Int>

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

    let tagsService: TagsService
    let mode: TagsViewMode

    var isBrowseMode: Bool {
        if case .browse = mode {
            return true
        }
        return false
    }

    init(blog: Blog, selectedTags: String? = nil, mode: TagsViewMode) {
        self.tagsService = TagsService(blog: blog)
        self.mode = mode
        self.selectedTags = AbstractPost.makeTags(from: selectedTags ?? "")
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

                let offset = pageIndex ?? 0
                let remoteTags = try await self.tagsService.getTags(
                    number: 100,
                    offset: offset,
                    orderBy: self.isBrowseMode ? .byCount : .byName,
                    order: self.isBrowseMode ? .orderDescending : .orderAscending
                )

                let hasMore = remoteTags.count == 100
                let nextPage = hasMore ? offset + 100 : nil

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

    func toggleSelection(for tag: RemotePostTag) {
        guard let tagName = tag.name else { return }
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
                _ = try await tagsService.createTag(named: name)
            } catch {
                removeSelectedTag(name)
            }
        }
    }

    func isSelected(_ tag: RemotePostTag) -> Bool {
        guard let tagName = tag.name else { return false }
        return selectedTagsSet.contains(tagName.lowercased())
    }

    func isNotSelected(_ tag: RemotePostTag) -> Bool {
        !isSelected(tag)
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
