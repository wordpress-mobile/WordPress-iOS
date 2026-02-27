import Foundation
import Testing
import WordPressAPI

@testable import WordPress

@MainActor
struct TagSelectionTests {

    // MARK: - toggleSelection

    @Test
    func toggleSelectionAddsTagItemWithCorrectIdAndName() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let tags = await mock.tags
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        viewModel.toggleSelection(for: tags[0])

        #expect(viewModel.selectedTags.count == 1)
        #expect(viewModel.selectedTags[0].id == Int(tags[0].id))
        #expect(viewModel.selectedTags[0].name == "Foo")
    }

    @Test
    func toggleSelectionRemovesPreviouslySelectedTag() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let tags = await mock.tags
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        viewModel.toggleSelection(for: tags[0])
        #expect(viewModel.selectedTags.count == 1)

        viewModel.toggleSelection(for: tags[0])
        #expect(viewModel.selectedTags.isEmpty)
    }

    // MARK: - addNewTag

    @Test
    func addNewTagAppendsPendingTagItem() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        let task = viewModel.addNewTag(named: "Baz")

        // Before the task completes, the tag should be pending
        #expect(viewModel.selectedTags.count == 1)
        #expect(viewModel.selectedTags[0].id == 0)
        #expect(viewModel.selectedTags[0].isPending)
        #expect(viewModel.selectedTags[0].name == "Baz")

        await task?.value
    }

    @Test
    func addNewTagReplacesPendingWithRealId() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        await viewModel.addNewTag(named: "Baz")?.value

        #expect(viewModel.selectedTags.count == 1)
        #expect(viewModel.selectedTags[0].id != 0)
        #expect(!viewModel.selectedTags[0].isPending)
        #expect(viewModel.selectedTags[0].name == "Baz")
    }

    @Test
    func addNewTagRemovesPendingOnError() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        await mock.setShouldThrow(true)
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        await viewModel.addNewTag(named: "Baz")?.value

        #expect(viewModel.selectedTags.isEmpty)
    }

    @Test
    func addNewTagIsNoOpForDuplicateName() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        await viewModel.addNewTag(named: "Baz")?.value
        let result = viewModel.addNewTag(named: "baz")

        #expect(result == nil)
        #expect(viewModel.selectedTags.count == 1)
    }

    @Test
    func addExistingTagUsesServerName() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        await viewModel.addNewTag(named: "foo")?.value

        #expect(viewModel.selectedTags.count == 1)
        #expect(viewModel.selectedTags[0].name == "Foo")
        #expect(viewModel.selectedTags[0].id != 0)
    }

    @Test
    func addNewTagCreatesOnServer() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        await viewModel.addNewTag(named: "Baz")?.value

        await #expect(mock.tags.count == 3)
    }

    // MARK: - Selection callback

    @Test
    func selectionCallbackFiltersOutPendingItems() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        var callbackTags: [TagsViewModel.SelectedTerm] = []
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: { tags in
            callbackTags = tags
        }))

        _ = viewModel.addNewTag(named: "Baz")

        // The pending item (id == 0) should be filtered out of the callback
        #expect(callbackTags.isEmpty)
    }

    @Test
    func selectionCallbackDeliversConfirmedItems() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let tags = await mock.tags
        var callbackTags: [TagsViewModel.SelectedTerm] = []
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: { tags in
            callbackTags = tags
        }))

        viewModel.toggleSelection(for: tags[0])

        #expect(callbackTags.count == 1)
        #expect(callbackTags[0].id == Int(tags[0].id))
    }

    // MARK: - getTerms

    @Test
    func getTermsReturnsMatchingTerms() async throws {
        let mock = MockService(tags: ["Foo", "Bar", "Baz"])
        let tags = await mock.tags
        let ids = [tags[0].id, tags[2].id]

        let result = try await mock.getTerms(ids: ids)

        #expect(result.count == 2)
        #expect(result.contains { $0.name == "Foo" })
        #expect(result.contains { $0.name == "Baz" })
    }

    @Test
    func getTermsWithEmptyIdsReturnsEmpty() async throws {
        let mock = MockService(tags: ["Foo", "Bar"])
        let result = try await mock.getTerms(ids: [])
        #expect(result.isEmpty)
    }

    // MARK: - removeSelectedTag

    @Test
    func removeSelectedTagByNameCaseInsensitive() async {
        let mock = MockService(tags: ["Foo", "Bar"])
        let tags = await mock.tags
        let viewModel = TagsViewModel(taxonomy: nil, service: mock, mode: .selection(onSelectedTagsChanged: nil))

        viewModel.toggleSelection(for: tags[0])
        #expect(viewModel.selectedTags.count == 1)

        viewModel.removeSelectedTag("foo")
        #expect(viewModel.selectedTags.isEmpty)
    }
}

private actor MockService: TaxonomyServiceProtocol {
    var tags: [AnyTermWithViewContext]
    private var shouldThrow = false

    init(tags: [String] = []) {
        self.tags = tags.map {
            AnyTermWithViewContext(
                id: (1...Int64.max).randomElement()!,
                count: 0,
                description: "",
                link: "",
                name: $0,
                slug: $0.lowercased(),
                taxonomy: .postTag,
                parent: nil
            )
        }
    }

    func setShouldThrow(_ value: Bool) {
        shouldThrow = value
    }

    func getTags(page: Int, recentlyUsed: Bool) async throws -> [AnyTermWithViewContext] {
        tags
    }

    func searchTags(with query: String) async throws -> [AnyTermWithViewContext] {
        if shouldThrow { throw URLError(.badServerResponse) }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func createTag(name: String, description: String) async throws -> AnyTermWithViewContext {
        if shouldThrow { throw URLError(.badServerResponse) }

        let lowercasedName = name.lowercased()
        if tags.contains(where: { $0.name.lowercased() == lowercasedName }) {
            let error = NSError(domain: "MockService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Tag already exists"])
            throw error
        }

        let newTag = AnyTermWithViewContext(
            id: (1...Int64.max).randomElement()!,
            count: 0,
            description: description,
            link: "",
            name: name,
            slug: name.lowercased(),
            taxonomy: .postTag,
            parent: nil
        )
        tags.append(newTag)
        return newTag
    }

    func updateTag(_ term: AnyTermWithViewContext, name: String, description: String) async throws -> AnyTermWithViewContext {
        guard let index = tags.firstIndex(where: { $0.id == term.id }) else {
            let error = NSError(domain: "MockService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Tag not found"])
            throw error
        }

        let updatedTag = AnyTermWithViewContext(
            id: term.id,
            count: term.count,
            description: description,
            link: term.link,
            name: name,
            slug: name.lowercased(),
            taxonomy: term.taxonomy,
            parent: term.parent
        )
        tags[index] = updatedTag
        return updatedTag
    }

    func deleteTag(_ term: AnyTermWithViewContext) async throws {
        tags.removeAll { $0.id == term.id }
    }

    func getTerms(ids: [Int64]) async throws -> [AnyTermWithViewContext] {
        let idSet = Set(ids)
        return tags.filter { idSet.contains($0.id) }
    }
}
