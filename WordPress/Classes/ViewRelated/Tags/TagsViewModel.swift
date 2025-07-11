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

    let blog: Blog
    private let tagsService: TagsService

    init(blog: Blog) {
        self.blog = blog
        self.tagsService = TagsService(blog: blog)
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
}
