import Foundation
import WordPressKit
import WordPressData
import WordPressUI

typealias TagsPaginatedResponse = DataViewPaginatedResponse<RemotePostTag, Int>

@MainActor
class TagsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var response: TagsPaginatedResponse?
    @Published var isLoading = false
    @Published var error: Error?
    @Published private(set) var selectedTags: [String] = [] {
        didSet {
            onSelectedTagsChanged?(selectedTags.joined(separator: ", "))
        }
    }
    private var selectedTagsSet: Set<String> = []

    private let tagsService: TagsService
    var onSelectedTagsChanged: ((String) -> Void)?

    init(blog: Blog, selectedTags: String? = nil, onSelectedTagsChanged: ((String) -> Void)? = nil) {
        self.tagsService = TagsService(blog: blog)
        self.selectedTags = selectedTags?.split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        } ?? []
        self.selectedTagsSet = Set(self.selectedTags.map { $0.lowercased() })
        self.onSelectedTagsChanged = onSelectedTagsChanged
    }

    func onAppear() {
        guard response == nil else { return }
        Task {
            await loadInitialTags()
        }
    }

    @MainActor
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
                let remoteTags = try await self.tagsService.getTags(number: 100, offset: offset)

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

    func search() async throws -> DataViewPaginatedResponse<RemotePostTag, Int> {
        let remoteTags = try await tagsService.searchTags(with: searchText)

        return try await DataViewPaginatedResponse { _ in
            return DataViewPaginatedResponse.Page(
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

    func removeSelectedTag(_ tagName: String) {
        let lowercasedTagName = tagName.lowercased()
        selectedTagsSet.remove(lowercasedTagName)
        selectedTags.removeAll { $0.lowercased() == lowercasedTagName }
    }
}
